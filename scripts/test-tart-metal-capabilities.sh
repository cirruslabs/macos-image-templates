#!/bin/bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source_dir="$script_dir/../data/tart-metal-capabilities"
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

DESTDIR="$work_dir/root" TART_METAL_SOURCE_DIR="$source_dir" \
  bash "$script_dir/install-tart-metal-capabilities.sh"
library="$work_dir/root/usr/local/lib/TartMetalCapabilities.dylib"
cmp "$source_dir/LICENSE" \
  "$work_dir/root/usr/local/share/licenses/tart-metal-capabilities/LICENSE"

xcrun clang -O2 -Wall -Wextra -Werror -fobjc-arc \
  -framework Foundation -framework Metal \
  "$source_dir/Tests/configuration.m" -o "$work_dir/configuration"
/usr/bin/env -u TART_METAL_APPLE_FAMILY_MAX \
  -u TART_METAL_MAX_THREADGROUP_MEMORY -u TART_METAL_RECOMMENDED_WORKING_SET_SIZE \
  "$work_dir/configuration"
for family in 1009 1008 0; do
  /usr/bin/env -u TART_METAL_MAX_THREADGROUP_MEMORY \
    -u TART_METAL_RECOMMENDED_WORKING_SET_SIZE \
    TART_METAL_APPLE_FAMILY_MAX="$family" "$work_dir/configuration" "$family"
done

xcrun clang -O2 -Wall -Wextra -Werror -arch arm64 -arch x86_64 \
  -mmacosx-version-min=12.0 "$source_dir/Tests/exec-environment.c" \
  -o "$work_dir/exec-environment"
run_injected() {
  "$@" /usr/bin/env DYLD_INSERT_LIBRARIES="$library" \
    TART_METAL_APPLE_FAMILY_MAX=1009 TART_METAL_MAX_THREADGROUP_MEMORY=65536 \
    "$work_dir/exec-environment" 1009
}
run_injected
if [[ $(uname -m) == arm64 ]]; then
  if arch -x86_64 /usr/bin/true; then
    run_injected arch -x86_64
  else
    echo "Rosetta runtime check skipped: Rosetta is not installed"
  fi
fi

for variant in agent daemon; do
  plist="$script_dir/../data/tart-guest-$variant.plist"
  plutil -lint "$plist"
  test "$(plutil -extract EnvironmentVariables.DYLD_INSERT_LIBRARIES raw "$plist")" = /usr/local/lib/TartMetalCapabilities.dylib
  test "$(plutil -extract EnvironmentVariables.TART_METAL_APPLE_FAMILY_MAX raw "$plist")" = 1009
  test "$(plutil -extract EnvironmentVariables.TART_METAL_MAX_THREADGROUP_MEMORY raw "$plist")" = 65536
done
