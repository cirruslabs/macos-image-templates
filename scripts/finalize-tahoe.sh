#!/bin/bash

source ~/.zprofile

# Set shell options to enable fail-fast behavior
#
# * -e: fail the script when an error occurs or command fails
# * -u: fail the script when attempting to reference unset parameters
# * -o pipefail: by default an exit status of a pipeline is that of its
#                last command, this fails the pipe early if an error in
#                any of its commands occurs
#
set -euo pipefail

# Wait until `xcrun simctl list devices -v` no longer reports any devices as "unavailable".
#
# Exit codes:
#   0 - Success: no devices are marked as unavailable within the timeout window
#   1 - Failure: timed out waiting for devices to become available
#   2 - Failure: prerequisites missing (e.g., xcrun not found)

DEFAULT_TIMEOUT_MINUTES=60
TIMEOUT_MINUTES=${1:-$DEFAULT_TIMEOUT_MINUTES}

if ! [[ "$TIMEOUT_MINUTES" =~ ^[0-9]+$ ]]; then
  echo "[wait-simulators] ERROR: TIMEOUT_MINUTES must be an integer number of minutes (got: '$TIMEOUT_MINUTES')." >&2
  exit 2
fi

SECONDS_TOTAL=$(( TIMEOUT_MINUTES * 60 ))
DEADLINE=$(( $(date +%s) + SECONDS_TOTAL ))
SLEEP_SECONDS=15

# Print a one-line status snapshot of current unavailable devices (if any)
print_status() {
  if xcrun simctl list devices -v | grep -qi "unavailable"; then
    echo "[wait-simulators] Still seeing 'unavailable' devices at $(date '+%Y-%m-%d %H:%M:%S')"
    # Show a concise list of unavailable lines for debugging
    xcrun simctl list devices -v | grep -i "unavailable" | sed 's/^/[wait-simulators]   /'
  else
    echo "[wait-simulators] No 'unavailable' devices detected at $(date '+%Y-%m-%d %H:%M:%S')"
  fi
}

trap 'echo "[wait-simulators] Interrupted" >&2; exit 130' INT TERM

echo "[wait-simulators] Waiting up to ${TIMEOUT_MINUTES} minute(s) for simulators to become available..."

while true; do
  if ! xcrun simctl list devices -v | grep -qi "unavailable"; then
    echo "[wait-simulators] All simulators are available."
    exit 0
  fi

  NOW=$(date +%s)
  if (( NOW >= DEADLINE )); then
    echo "[wait-simulators] TIMEOUT after ${TIMEOUT_MINUTES} minute(s). Some simulators remain 'unavailable'." >&2
    echo "[wait-simulators] Final snapshot of unavailable devices:" >&2
    xcrun simctl list devices -v | grep -i "unavailable" | sed 's/^/[wait-simulators]   /' >&2
    exit 1
  fi

  print_status
  REMAIN=$(( DEADLINE - NOW ))
  # Sleep in chunks to allow quicker exit when they become available
  SLEEP=$SLEEP_SECONDS
  if (( REMAIN < SLEEP_SECONDS )); then SLEEP=$REMAIN; fi
  sleep "$SLEEP"
  # Loop and re-check
done


