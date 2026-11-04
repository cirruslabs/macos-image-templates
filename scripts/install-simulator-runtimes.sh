#!/bin/bash
set -euo pipefail

# Export in this VM, remove the source MobileAsset, then import the saved package.
# Export/import alone leaves assets that can override the import on the next VM
# boot. See macos-image-templates#391.
case "${1:-}" in
  -downloadPlatform|-downloadAllPlatforms) ;;
  *) echo "Usage: $0 -downloadPlatform PLATFORM [-buildVersion VERSION] | -downloadAllPlatforms" >&2; exit 2 ;;
esac

export_dir=$(mktemp -d "${TMPDIR:-/tmp}/simulator-runtimes.XXXXXX")
trap 'rm -rf "$export_dir"' EXIT

download_status=0
xcodebuild "$@" -exportPath "$export_dir" || download_status=$?

# Xcode can finish exporting a runtime but return EX_SOFTWARE. Do not suppress
# other failures, accept an empty export, or ignore a failed import. The image's
# expected-runtime comparison also checks for missing builds in multi-exports.
if [[ $download_status -ne 0 && $download_status -ne 70 ]]; then
  echo "Simulator runtime export failed (exit $download_status)." >&2
  exit "$download_status"
fi

shopt -s nullglob
packages=("$export_dir"/*.exportedBundle "$export_dir"/*.dmg)
if [[ ${#packages[@]} -eq 0 ]]; then
  echo "No simulator runtime packages were exported (exit $download_status)." >&2
  exit 1
fi

for package in "${packages[@]}"; do
  echo "Importing simulator runtime: $(basename "$package")"
  python3 "$(dirname "${BASH_SOURCE[0]}")/import-simulator-runtime.py" "$package"
done
