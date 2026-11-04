#!/usr/bin/env python3
"""Replace a runtime in a disposable image build using a saved export.

MobileAsset files left by export can override the imported runtime on the next
VM boot. Remove both their registrations and their files before the final import.
Never use this provisioning helper on a machine running simulator jobs.
"""

import json
from pathlib import Path
import plistlib
import subprocess
import sys
import time


PLATFORMS = {
    "com.apple.MobileAsset.iOSSimulatorRuntime": "com.apple.platform.iphonesimulator",
    "com.apple.MobileAsset.watchOSSimulatorRuntime": "com.apple.platform.watchsimulator",
    "com.apple.MobileAsset.appleTVOSSimulatorRuntime": "com.apple.platform.appletvsimulator",
    "com.apple.MobileAsset.xrOSSimulatorRuntime": "com.apple.platform.xrsimulator",
}


def registry():
    return json.loads(subprocess.check_output(["xcrun", "simctl", "runtime", "list", "-j"], text=True))


def run(*args, check=True):
    return subprocess.run(args, check=check)


def bundle_identity(package):
    with (package / "ExportedMetadata.plist").open("rb") as file:
        metadata = plistlib.load(file)
    properties = metadata["MobileAssetProperties"]
    platform = PLATFORMS[metadata["CFBundleIdentifier"]]
    build = properties["Build"]
    architectures = sorted(properties["Architectures"])
    if not build or not architectures:
        raise ValueError("Exported runtime metadata is incomplete")
    return platform, build, architectures


def matches(image, identity):
    platform, build, architectures = identity
    return (image.get("platformIdentifier") == platform and image.get("build") == build
            and sorted(image.get("supportedArchitectures", [])) == architectures)


def remove_existing(identity):
    paths = set()
    asset_roots = set()
    rescans = 0

    def targets(images):
        # A rescanned/Copying registration may not yet have build metadata.
        return {key: image for key, image in images.items()
                if matches(image, identity) or Path(image.get("path", "")) in paths or any(
                    root == Path(image.get("path", "")) or root in Path(image.get("path", "")).parents
                    for root in asset_roots)}

    # scan-and-mount is asynchronous. Allow its registrations to appear rather
    # than interpreting a temporarily empty registry as successful asset removal.
    for attempt in range(24):
        images = targets(registry())
        for image in images.values():
            if not image.get("path"):
                raise ValueError("Runtime registration has no storage path")
            path = Path(image["path"])
            paths.add(path)
            if "/com_apple_MobileAsset_" in str(path):
                asset_roots.update(parent for parent in (path, *path.parents) if parent.suffix == ".asset")

        for identifier in images:
            # Deleting one MobileAsset registration can also remove its twins.
            if identifier in registry():
                print(f"Removing previous runtime registration {identifier}", flush=True)
                run("sudo", "xcrun", "simctl", "runtime", "delete", identifier, check=False)

        # A successful registry deletion alone is insufficient: simctl can return
        # error 30 and leave its MobileAsset behind. Verify the files as well.
        if not targets(registry()) and not any(path.exists() for path in paths | asset_roots):
            return
        if images and rescans < 3:
            print("Rescanning runtime storage before retrying source cleanup", flush=True)
            run("xcrun", "simctl", "runtime", "scan-and-mount")
            rescans += 1
        if attempt < 23:
            time.sleep(5)

    raise RuntimeError(f"Could not remove the previous runtime and its assets: {identity[:2]}")


def install(package):
    package = Path(package)
    if package.suffix == ".exportedBundle":
        # The export survives deletion of the original registration and assets.
        # Replacing existing managed copies also prevents repeated Xcode setup
        # steps from accumulating imported duplicates for the same build.
        identity = bundle_identity(package)
        remove_existing(identity)
    elif package.suffix != ".dmg":
        raise ValueError(f"Unsupported simulator runtime package: {package}")
    run("xcodebuild", "-importPlatform", str(package))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("Usage: import-simulator-runtime.py EXPORTED_PACKAGE")
    install(sys.argv[1])
