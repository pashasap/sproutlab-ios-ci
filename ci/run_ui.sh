#!/bin/bash
set +e
CUTOFF=$1
A=ci/artifacts; mkdir -p $A/stall /tmp/audit-stops
XTR=$(ls ci/DD/Build/Products/*.xctestrun | head -1)
xcrun simctl boot "$SIM_UDID"; xcrun simctl bootstatus "$SIM_UDID" -b > /dev/null
echo "TIMING booted at $(( $(date +%s) - JOB_T0 ))s"
xcrun simctl ui "$SIM_UDID" appearance light
start_test () {
  NSUnbufferedIO=YES xcodebuild test-without-building -xctestrun "$XTR" \
    -destination "platform=iOS Simulator,id=$SIM_UDID" \
    -only-testing:AuditStopsUITests/AuditStopsUITests/testStops > $A/test.log 2>&1 &
  pid=$!
}
start_test; retried=0; i=0; done_at=0; last=""; same=0
while kill -0 $pid 2>/dev/null; do
  sleep 1; i=$((i+1))
  if [ $(( $(date +%s) - JOB_T0 )) -gt $CUTOFF ]; then
    echo "OUTCOME cutoff at $CUTOFF s" | tee -a $A/outcome.txt
    xcrun simctl io "$SIM_UDID" screenshot $A/stall/cutoff.png > /dev/null 2>&1; break
  fi
  if [ $retried -eq 0 ] && [ $i -ge 120 ] && ! grep -q "Test Case" $A/test.log; then
    echo "OUTCOME test start stalled once" | tee -a $A/outcome.txt
    cp $A/test.log $A/test-stalled-start.log; kill $pid; sleep 2; kill -9 $pid 2>/dev/null
    pkill -f "xcodebuild test-without-building"; sleep 2; retried=1; i=0; start_test
  fi
  if [ $done_at -eq 0 ] && grep -qE "Test Case .*(passed|failed)" $A/test.log; then done_at=$i; fi
  if [ $done_at -gt 0 ] && [ $((i - done_at)) -ge 6 ]; then break; fi
  cur=$(wc -l < $A/test.log)
  if [ "$cur" = "$last" ]; then same=$((same+1)); else same=0; last=$cur; fi
  if [ $same -eq 45 ]; then
    echo "OUTCOME no test output for 45 s at t=$i" | tee -a $A/outcome.txt
    xcrun simctl io "$SIM_UDID" screenshot $A/stall/t$i.png > /dev/null 2>&1
  fi
done
kill $pid 2>/dev/null; sleep 1; kill -9 $pid 2>/dev/null
echo "TIMING test done at $(( $(date +%s) - JOB_T0 ))s"
true
