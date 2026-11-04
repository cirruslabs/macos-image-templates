#!/bin/bash
set -euo pipefail

timeout_seconds=${1:-900}
stable_seconds=${2:-120}
if ! [[ "$timeout_seconds" =~ ^[1-9][0-9]*$ && "$stable_seconds" =~ ^[1-9][0-9]*$ ]]; then
  echo "Usage: $0 [timeout seconds] [stable seconds] (positive integers)" >&2
  exit 2
fi

snapshot=$(mktemp)
trap 'rm -f "$snapshot"' EXIT
started=$(date +%s)
stable_since=0
previous=''

while true; do
  # Fail on a broken simctl call; an empty or failed listing is not readiness.
  xcrun simctl runtime list -j > "$snapshot"
  now=$(date +%s)
  signature=$(jq -cS 'to_entries | map([.key, .value.state, .value.path]) | sort' "$snapshot")
  if jq -e '
    length > 0 and
    all(.[]; .state == "Ready" and
      (.path | contains("/com_apple_MobileAsset_") | not)) and
    ([.[] | [.platformIdentifier, .build]] | group_by(.) | all(.[]; length == 1))
  ' "$snapshot" > /dev/null; then
    if [[ "$signature" != "$previous" || $stable_since -eq 0 ]]; then
      stable_since=$now
      echo "Imported simulator runtimes are ready; checking registration stability."
    fi
    if (( now - stable_since >= stable_seconds )); then
      echo "Imported simulator registrations have been stable for $stable_seconds seconds."
      exit 0
    fi
  else
    stable_since=0
    if [[ "$signature" != "$previous" ]]; then
      echo "Waiting for simulator imports and MobileAsset duplicate cleanup:"
      jq -r '.[] | "  \(.identifier): \(.state) \(.path)"' "$snapshot"
    fi
  fi
  previous=$signature

  if (( now - started >= timeout_seconds )); then
    echo "Simulator runtime registrations did not settle within $timeout_seconds seconds." >&2
    cat "$snapshot" >&2
    exit 1
  fi
  sleep 15
done
