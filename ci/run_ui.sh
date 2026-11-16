#!/bin/bash
# One XCTest method per audit stop. XCTest's own time allowance (60 s, its minimum) kills a test whose app does not
# respond, attaches a spindump to the result bundle, restarts the runner and goes on with the next stop.
#
# Time budget (seconds after JOB_T0, set by the workflow's first step; operator decision 2026-11-16, D-20261116-p-1: the job takes at
# most 15 minutes when no stop timed out, at most 20 when at least one did):
#   $1 = cutoff while no test timed out. After it come: the bundle's finalize wait (FINALIZE_S), Collect (about 15 s),
#        Upload (about 10 s) and the runner's own start and end (about 70 s): all inside 900 s.
#   $2 = cutoff once a timeout was seen (the spindump and the runner restart cost 90 to 130 s). Collect then also
#        exports from a finalized bundle and zips it (about 60 s): all inside 1200 s.
# The cutoff stays a last resort; it asks xcodebuild to stop (SIGTERM, which it answers with `BUILD INTERRUPTED`) and
# waits up to FINALIZE_S for it to finalize the result bundle (FINALIZE_TIMEOUT_S after the last test when one timed out).
set +e
CUTOFF=$1; EXTENDED=${2:-$1}; FINALIZE_S=${FINALIZE_S:-25}; FINALIZE_TIMEOUT_S=${FINALIZE_TIMEOUT_S:-90}
STALL_S=${STALL_S:-45}; QUIET_S=${QUIET_S:-200}  # the notice below; the quiet window after a timeout (the spindump)
A=ci/artifacts; mkdir -p $A/stall /tmp/audit-stops
XTR=$(ls ci/DD/Build/Products/*.xctestrun | head -1)
RESULT=$A/result.xcresult
# the simulator boots here, after the build: booting it during the build slowed the build from about 40 s to 5 minutes
# and stalled it (public runs 43831317133, 43833664522, 43834818284); it takes 3 to 4 minutes
xcrun simctl boot "$SIM_UDID" > /dev/null 2>&1
xcrun simctl bootstatus "$SIM_UDID" -b > /dev/null
echo "TIMING booted at $(( $(date +%s) - JOB_T0 ))s"
xcrun simctl ui "$SIM_UDID" appearance light
# a screenshot of a simulator that does not answer must not cost the budget: it gets 8 s
shot () {
  xcrun simctl io "$SIM_UDID" screenshot $A/stall/$1.png > /dev/null 2>&1 & local p=$!
  for _ in $(seq 1 8); do kill -0 $p 2>/dev/null || return 0; sleep 1; done
  kill $p 2>/dev/null
}
start_test () {
  rm -rf $RESULT
  NSUnbufferedIO=YES xcodebuild test-without-building -xctestrun "$XTR" \
    -destination "platform=iOS Simulator,id=$SIM_UDID" \
    -test-timeouts-enabled YES -default-test-execution-time-allowance 60 -maximum-test-execution-time-allowance 60 \
    -parallel-testing-enabled NO -resultBundlePath $RESULT \
    -only-testing:AuditStopsUITests/AuditStopsUITests > $A/test.log 2>&1 &
  pid=$!
}
start_test; retried=0; i=0; done_at=0; last=""; same=0; timeout_at=0
while kill -0 $pid 2>/dev/null; do
  sleep 1; i=$((i+1)); now=$(( $(date +%s) - JOB_T0 ))
  if [ $timeout_at -eq 0 ] && grep -q "exceeded execution time allowance" $A/test.log; then
    timeout_at=$now; CUTOFF=$EXTENDED
    echo "OUTCOME a test timed out at $now s: the cutoff moves to $EXTENDED s" | tee -a $A/outcome.txt
  fi
  if [ $now -gt $CUTOFF ]; then
    echo "OUTCOME cutoff at $CUTOFF s" | tee -a $A/outcome.txt
    shot cutoff; break
  fi
  if [ $retried -eq 0 ] && [ $i -ge 120 ] && ! grep -q "Test Case" $A/test.log; then
    echo "OUTCOME test start stalled once" | tee -a $A/outcome.txt
    cp $A/test.log $A/test-stalled-start.log; kill $pid; sleep 2; kill -9 $pid 2>/dev/null
    pkill -f "xcodebuild test-without-building"; sleep 2; retried=1; i=0; start_test
  fi
  # every stop is its own test: the run is over when the whole selection is reported, not when one test is
  if [ $done_at -eq 0 ] && grep -qE "^Test Suite 'Selected tests' (passed|failed)" $A/test.log; then done_at=$i; fi
  # then xcodebuild finalizes the result bundle and exits by itself; give it time, then stop waiting. After a timeout it
  # collects diagnostics first (it was still busy 36 s after the last test in public run 43831317133): wait longer, the
  # extended cutoff still bounds this loop
  wait_s=$FINALIZE_S; [ $timeout_at -gt 0 ] && wait_s=$FINALIZE_TIMEOUT_S
  if [ $done_at -gt 0 ] && [ $((i - done_at)) -ge $wait_s ]; then break; fi
  cur=$(wc -l < $A/test.log)
  if [ "$cur" = "$last" ]; then same=$((same+1)); else same=0; last=$cur; fi
  # no output for 45 s is a stall, except while XCTest collects the spindump of a timed-out test (up to ~200 s of quiet)
  if [ $same -eq $STALL_S ] && { [ $timeout_at -eq 0 ] || [ $(( now - timeout_at )) -gt $QUIET_S ]; }; then
    echo "OUTCOME no test output for $STALL_S s at t=$i" | tee -a $A/outcome.txt
    shot t$i
  fi
done
if kill -0 $pid 2>/dev/null; then
  kill $pid  # a xcodebuild killed outright leaves the bundle without Info.plist: ask it to stop and let it finalize
  for _ in $(seq 1 $FINALIZE_S); do kill -0 $pid 2>/dev/null || break; sleep 1; done
  kill -9 $pid 2>/dev/null
fi
if [ -f $RESULT/Info.plist ]; then echo "TIMING result bundle finalized"; else echo "OUTCOME result bundle not finalized" | tee -a $A/outcome.txt; fi
# leave nothing running for the runner to clean up after the job (its "Complete job" took 2 min 10 s once, with a simulator
# and a test runner still alive, and 12 to 40 s otherwise)
pkill -x AuditStopsUITests-Runner 2>/dev/null
xcrun simctl shutdown "$SIM_UDID" > /dev/null 2>&1 & p=$!
for _ in $(seq 1 15); do kill -0 $p 2>/dev/null || break; sleep 1; done
echo "TIMING test done at $(( $(date +%s) - JOB_T0 ))s"
true
