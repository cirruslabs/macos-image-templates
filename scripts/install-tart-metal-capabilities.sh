#!/bin/bash
set -euo pipefail

# Packer supplies the uploaded source directory. Local builds use the vendored
# copy next to this script, so building an image needs no upstream download.
source_dir=${TART_METAL_SOURCE_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")/../data/tart-metal-capabilities" && pwd)"}
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
test -f "$source_dir/LICENSE"

# One path must work for the native guest agent, arm64e processes, and Rosetta
# children. Keep the deployment target compatible with the oldest template.
xcrun clang \
  -arch arm64 -arch arm64e -arch x86_64 \
  -O3 -Wall -Wextra -Werror -fobjc-arc -fblocks -fvisibility=hidden \
  -dynamiclib -install_name /usr/local/lib/TartMetalCapabilities.dylib \
  -mmacosx-version-min=12.0 -framework Foundation -framework Metal \
  "$source_dir/Sources/TartMetalCapabilities.m" -o "$work_dir/TartMetalCapabilities.dylib"
codesign --force --sign - "$work_dir/TartMetalCapabilities.dylib"
# Xcode 27's lipo rejects multiple architectures in one -verify_arch call.
for architecture in arm64 arm64e x86_64; do
  lipo "$work_dir/TartMetalCapabilities.dylib" -verify_arch "$architecture"
done
codesign --verify --strict "$work_dir/TartMetalCapabilities.dylib"

# DESTDIR allows the exact installer to be exercised without modifying the host.
install_root=${DESTDIR:-}
install_command=(sudo install -o root -g wheel)
if [[ -n "$install_root" ]]; then
  install_command=(install)
fi
"${install_command[@]}" -d -m 0755 "$install_root/usr/local/lib" \
  "$install_root/usr/local/share/licenses/tart-metal-capabilities"
"${install_command[@]}" -m 0644 "$work_dir/TartMetalCapabilities.dylib" \
  "$install_root/usr/local/lib/TartMetalCapabilities.dylib"
"${install_command[@]}" -m 0644 "$source_dir/LICENSE" \
  "$install_root/usr/local/share/licenses/tart-metal-capabilities/LICENSE"
