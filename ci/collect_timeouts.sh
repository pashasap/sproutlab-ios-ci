#!/bin/bash
# After the run: which stop tests XCTest timed out (`timed_out.txt`, one stop id per line, read from the xcodebuild log)
# and the result bundle zipped for the factory, which reads the spindump out of it (a spindump read on the runner cost
# 88 to 126 s of the job). Only when a test timed out and xcodebuild finalized the bundle, the documented
# `xcresulttool` exports run too, each capped at 20 s; the factory reads the bundle itself either way.
set +e
A=ci/artifacts; R=$A/result.xcresult
capped () { local s=$1; shift; "$@" & local p=$!; ( sleep $s; kill $p 2>/dev/null ) & local w=$!; wait $p; kill $w 2>/dev/null; }
sed -nE "s/.*Test Case '-\[[^ ]+ test_[0-9]+_([a-z0-9_]+)\]' exceeded execution time allowance.*/\1/p" $A/test.log 2>/dev/null \
  | tr '_' '-' | sort -u > $A/timed_out.txt
echo "TIMING timed out: $(tr '\n' ' ' < $A/timed_out.txt)"
if [ -d $R ]; then
  if [ -s $A/timed_out.txt ]; then
    if [ -f $R/Info.plist ]; then
      mkdir -p $A/xcresult-diagnostics
      capped 20 xcrun xcresulttool get test-results tests --path $R > $A/xcresult-tests.json 2> $A/xcresult-tests.err
      capped 20 xcrun xcresulttool export diagnostics --path $R --output-path $A/xcresult-diagnostics > $A/xcresult-export.log 2>&1
    else
      echo "the result bundle was not finalized (no Info.plist): xcresulttool cannot read it, the factory reads its blobs" > $A/xcresult-export.log
    fi
  fi
  ditto -c -k --keepParent $R $A/result.xcresult.zip 2>/dev/null
  [ "$(stat -f %z $A/result.xcresult.zip 2>/dev/null || echo 0)" -gt 100000000 ] && rm -f $A/result.xcresult.zip
  rm -rf $R
fi
true
