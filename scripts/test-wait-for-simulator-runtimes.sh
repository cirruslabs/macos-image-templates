#!/bin/bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export RUNTIME_WAIT_TEST_ROOT
RUNTIME_WAIT_TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$RUNTIME_WAIT_TEST_ROOT"' EXIT

# These fixtures use the runtime registry format observed in Xcode 27.2.
xcrun() {
  [[ "$*" == 'simctl runtime list -j' ]] || return 2
  local count
  count=$(( $(cat "$RUNTIME_WAIT_TEST_ROOT/count") + 1 ))
  echo "$count" > "$RUNTIME_WAIT_TEST_ROOT/count"
  case "$RUNTIME_WAIT_TEST_CASE" in
    failed) return 99 ;;
    empty) echo '{}'; return ;;
    duplicate)
      echo '{"A":{"identifier":"A","state":"Ready","path":"/Library/Developer/CoreSimulator/Cryptex/Images/A","platformIdentifier":"iOS","build":"23B80"},"B":{"identifier":"B","state":"Ready","path":"/Library/Developer/CoreSimulator/Cryptex/Images/B","platformIdentifier":"iOS","build":"23B80"}}'
      return
      ;;
    asset)
      echo '{"A":{"identifier":"A","state":"Ready","path":"/System/Library/AssetsV2/com_apple_MobileAsset_iOSSimulatorRuntime/test.asset/AssetData","platformIdentifier":"iOS","build":"23B80"}}'
      return
      ;;
  esac
  local id=A state=Ready
  if [[ "$RUNTIME_WAIT_TEST_CASE" == churn && $count -ge 2 ]]; then id=B; fi
  if [[ "$RUNTIME_WAIT_TEST_CASE" == unusable && $count -eq 2 ]]; then state=Unusable; fi
  printf '{"%s":{"identifier":"%s","state":"%s","path":"/Library/Developer/CoreSimulator/Cryptex/Images/%s","platformIdentifier":"iOS","build":"23B80"}}\n' "$id" "$id" "$state" "$id"
}
date() {
  [[ "$*" == '+%s' ]] || return 2
  echo $(( 1000 + $(cat "$RUNTIME_WAIT_TEST_ROOT/count") * 15 ))
}
sleep() { [[ "$1" == 15 ]]; }
export -f xcrun date sleep

run_case() {
  export RUNTIME_WAIT_TEST_CASE="$1"
  local expected_status="$2" expected_calls="$3" status=0
  echo 0 > "$RUNTIME_WAIT_TEST_ROOT/count"
  bash "$script_dir/wait-for-simulator-runtimes.sh" 150 30 > "$RUNTIME_WAIT_TEST_ROOT/output" 2>&1 || status=$?
  if [[ "$status" != "$expected_status" || $(cat "$RUNTIME_WAIT_TEST_ROOT/count") != "$expected_calls" ]]; then
    cat "$RUNTIME_WAIT_TEST_ROOT/output" >&2
    echo "Unexpected result for $1: exit $status, $(cat "$RUNTIME_WAIT_TEST_ROOT/count") samples" >&2
    exit 1
  fi
}

run_case ready 0 3
run_case churn 0 4
run_case unusable 0 5
run_case asset 1 10
run_case duplicate 1 10
run_case empty 1 10
run_case failed 99 1
echo 'Simulator runtime settling tests passed'
