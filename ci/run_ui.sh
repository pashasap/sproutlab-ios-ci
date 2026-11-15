#!/bin/bash
# Boots one simulator ($SIM_UDID), runs one UI test, and serves the test's REQUEST lines
# (dark, light, xl, seed). Stops at job-elapsed $2 seconds so the artifact steps still run.
set +e
TEST=$1; CUTOFF=$2
A=ci/artifacts; mkdir -p $A/stall /tmp/slctl /tmp/slshots
XTR=$(ls ci/DD/Build/Products/*.xctestrun | head -1); echo "xctestrun=$XTR"
xcrun simctl boot "$SIM_UDID"; xcrun simctl bootstatus "$SIM_UDID" -b > /dev/null
echo "booted at $(( $(date +%s) - JOB_T0 ))s"
xcrun simctl ui "$SIM_UDID" appearance light
t=$(date +%s)
NSUnbufferedIO=YES xcodebuild test-without-building -xctestrun "$XTR" \
  -destination "platform=iOS Simulator,id=$SIM_UDID" \
  -only-testing:SproutLabUITests/SproutLabUITests/$TEST > $A/test.log 2>&1 &
pid=$!; last=""; same=0; done_at=0; i=0
seed () {
  C=$(xcrun simctl get_app_container "$SIM_UDID" com.example.SproutLab data)
  F="$C/Library/Application Support/progress.json"
  python3 -I ci/seed_progress.py "$F"
}
while kill -0 $pid 2>/dev/null; do
  sleep 1; i=$((i+1))
  if [ $(( $(date +%s) - JOB_T0 )) -gt $CUTOFF ]; then echo "JOB CUTOFF at t=$i"; xcrun simctl io "$SIM_UDID" screenshot $A/stall/cutoff.png > /dev/null 2>&1; break; fi
  if [ $done_at -eq 0 ] && grep -qE "Test Case .*(passed|failed)" $A/test.log; then done_at=$i; fi
  if [ $done_at -gt 0 ] && [ $((i - done_at)) -ge 6 ]; then echo "test finished; stopping lingering xcodebuild"; break; fi
  for w in dark light xl seed; do
    if [ ! -f /tmp/slctl/$w-ok ] && grep -q "REQUEST $w$" $A/test.log; then
      case $w in
        xl) xcrun simctl ui "$SIM_UDID" content_size accessibility-extra-large ;;
        seed) seed ;;
        *) xcrun simctl ui "$SIM_UDID" appearance $w ;;
      esac
      touch /tmp/slctl/$w-ok; echo "host -> $w at t=$i"
    fi
  done
  cur=$(grep -c "AUDIT\|t = " $A/test.log)
  if [ "$cur" = "$last" ]; then same=$((same+1)); else same=0; last=$cur; fi
  if [ $same -eq 30 ]; then
    APP=$(pgrep -f "SproutLab.app/SproutLab" | head -1)
    echo "STALL? t=$i app=${APP:-none} last=$(grep AUDIT $A/test.log | tail -1 | cut -c1-200)" | tee -a $A/stall/watch.txt
    xcrun simctl io "$SIM_UDID" screenshot $A/stall/t$i.png > /dev/null 2>&1
    [ -n "$APP" ] && sample "$APP" 2 -file $A/stall/t$i-sample.txt > /dev/null 2>&1
  fi
done
kill $pid 2>/dev/null; sleep 1; kill -9 $pid 2>/dev/null
echo "TIMING test=$(( $(date +%s) - t ))s at $(( $(date +%s) - JOB_T0 ))s result=$(grep -E 'Test Case .*(passed|failed)' $A/test.log | tail -1)"
echo "shots: $(grep -c 'AUDIT .* shot ' $A/test.log)"
grep -E "AUDIT .*(ABSENT|NOT ADVANCED|did not open|acknowledged)" $A/test.log | cut -c1-300
xcrun simctl shutdown "$SIM_UDID"
true
