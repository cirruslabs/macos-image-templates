#!/bin/bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export RUNTIME_TEST_ROOT
RUNTIME_TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$RUNTIME_TEST_ROOT"' EXIT
mkdir "$RUNTIME_TEST_ROOT/tmp"
export TMPDIR="$RUNTIME_TEST_ROOT/tmp"

# Exercise failure handling without downloading or registering host runtimes.
xcodebuild() {
  if [[ "$1" == -importPlatform ]]; then
    [[ $# == 2 && -e "$2" ]] || return 2
    printf '%s\n' "$(basename "$2")" >> "$RUNTIME_TEST_ROOT/imports"
    return "$RUNTIME_TEST_IMPORT_STATUS"
  fi
  printf '%s\n' "$@" > "$RUNTIME_TEST_ROOT/arguments"
  local export_dir="${!#}"
  [[ "${*: -2:1}" == -exportPath ]] || return 2
  case "$RUNTIME_TEST_PACKAGES" in
    bundle) mkdir "$export_dir/iOS 26.1.exportedBundle" ;;
    dmg) touch "$export_dir/iOS 18.6 Simulator Runtime.dmg" ;;
    multiple)
      mkdir "$export_dir/iOS 27.2.exportedBundle" "$export_dir/iOS 27.2 iPhone.exportedBundle"
      # A disk image inside a bundle must not be imported separately.
      touch "$export_dir/iOS 27.2.exportedBundle/internal.dmg"
      touch "$export_dir/watchOS 27.0.dmg"
      ;;
    empty) ;;
  esac
  return "$RUNTIME_TEST_EXPORT_STATUS"
}
export -f xcodebuild

# The Python helper has separate tests for scoped asset deletion. Keep these
# shell tests focused on export failure handling and package discovery.
python3() {
  [[ $# == 2 && "$1" == */import-simulator-runtime.py ]] || return 2
  xcodebuild -importPlatform "$2"
}
export -f python3

run_case() {
  local expected_status="$1" actual_status=0
  : > "$RUNTIME_TEST_ROOT/imports"
  bash "$script_dir/install-simulator-runtimes.sh" -downloadPlatform iOS -buildVersion 26.1 > "$RUNTIME_TEST_ROOT/output" 2>&1 || actual_status=$?
  if [[ "$actual_status" != "$expected_status" ]]; then
    cat "$RUNTIME_TEST_ROOT/output" >&2
    echo "Expected exit $expected_status, got $actual_status" >&2
    exit 1
  fi
  [[ $(ls -A "$TMPDIR" | wc -l) -eq 0 ]] || { echo 'Export temporary files leaked' >&2; exit 1; }
}

export RUNTIME_TEST_EXPORT_STATUS=0 RUNTIME_TEST_IMPORT_STATUS=0 RUNTIME_TEST_PACKAGES=bundle
run_case 0
[[ $(cat "$RUNTIME_TEST_ROOT/imports") == 'iOS 26.1.exportedBundle' ]]
[[ $(head -n 4 "$RUNTIME_TEST_ROOT/arguments") == $'-downloadPlatform\niOS\n-buildVersion\n26.1' ]]

RUNTIME_TEST_EXPORT_STATUS=70
run_case 0
RUNTIME_TEST_EXPORT_STATUS=0
RUNTIME_TEST_PACKAGES=dmg
run_case 0
[[ $(cat "$RUNTIME_TEST_ROOT/imports") == 'iOS 18.6 Simulator Runtime.dmg' ]]

RUNTIME_TEST_EXPORT_STATUS=70
RUNTIME_TEST_PACKAGES=multiple
run_case 0
[[ $(wc -l < "$RUNTIME_TEST_ROOT/imports") -eq 3 ]]
: > "$RUNTIME_TEST_ROOT/imports"
bash "$script_dir/install-simulator-runtimes.sh" -downloadAllPlatforms > "$RUNTIME_TEST_ROOT/output" 2>&1
[[ $(head -n 1 "$RUNTIME_TEST_ROOT/arguments") == -downloadAllPlatforms ]]
[[ $(wc -l < "$RUNTIME_TEST_ROOT/imports") -eq 3 ]]

RUNTIME_TEST_PACKAGES=empty
run_case 1
RUNTIME_TEST_EXPORT_STATUS=0
run_case 1

RUNTIME_TEST_PACKAGES=bundle
RUNTIME_TEST_EXPORT_STATUS=69
run_case 69
[[ ! -s "$RUNTIME_TEST_ROOT/imports" ]]

RUNTIME_TEST_EXPORT_STATUS=70
RUNTIME_TEST_IMPORT_STATUS=65
run_case 65
RUNTIME_TEST_PACKAGES=multiple
run_case 65
[[ $(wc -l < "$RUNTIME_TEST_ROOT/imports") -eq 1 ]]

echo 'Simulator runtime installation tests passed'
