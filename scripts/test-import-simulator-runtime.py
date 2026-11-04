#!/usr/bin/env python3
import importlib.util
import json
from pathlib import Path
import plistlib
import shutil
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("runtime_import", Path(__file__).with_name("import-simulator-runtime.py"))
runtime_import = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runtime_import)


class RuntimeImportTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.package = self.root / "iOS.exportedBundle"
        self.package.mkdir()
        self.metadata = {
            "CFBundleIdentifier": "com.apple.MobileAsset.iOSSimulatorRuntime",
            "MobileAssetProperties": {"Build": "23B80", "Architectures": ["arm64"]},
        }
        self.write_metadata()
        self.asset = self.root / "com_apple_MobileAsset_iOSSimulatorRuntime" / "source.asset"
        (self.asset / "AssetData" / "Restore").mkdir(parents=True)
        (self.asset / "AssetData" / "Restore" / "runtime.dmg").touch()
        self.images = {"source": self.image(self.asset / "AssetData")}
        self.calls = []
        self.fail_first_reclaim = False
        self.fail_all_deletes = False
        self.addCleanup(patch.stopall)
        patch.object(runtime_import, "registry", side_effect=lambda: json.loads(json.dumps(self.images))).start()
        patch.object(runtime_import, "run", side_effect=self.run_command).start()
        patch.object(runtime_import.time, "sleep").start()

    def write_metadata(self):
        (self.package / "ExportedMetadata.plist").write_bytes(plistlib.dumps(self.metadata))

    def image(self, path, build="23B80", architectures=None):
        return {"platformIdentifier": "com.apple.platform.iphonesimulator", "build": build,
                "supportedArchitectures": architectures or ["arm64"], "path": str(path)}

    def run_command(self, *args, **kwargs):
        self.calls.append(args)
        if args[:5] == ("sudo", "xcrun", "simctl", "runtime", "delete"):
            if self.fail_all_deletes:
                return
            image = self.images.pop(args[5])
            if self.fail_first_reclaim:
                # simctl error 30: the registration is gone but the asset is not.
                self.fail_first_reclaim = False
                return
            path = Path(image["path"])
            if self.asset in path.parents:
                shutil.rmtree(self.asset)
            elif path.is_dir():
                shutil.rmtree(path)
        elif args == ("xcrun", "simctl", "runtime", "scan-and-mount"):
            if self.asset.exists():
                self.images["rescanned"] = self.image(self.asset / "AssetData" / "Restore" / "runtime.dmg")
        elif args[:2] == ("xcodebuild", "-importPlatform"):
            if self.package.suffix == ".exportedBundle":
                self.assertFalse(self.asset.exists(), "Imported before the source asset was removed")
            return
        else:
            self.fail(f"Unexpected command: {args}")

    def test_source_is_physically_removed_before_import(self):
        runtime_import.install(self.package)
        self.assertEqual(self.calls[-1], ("xcodebuild", "-importPlatform", str(self.package)))
        self.assertEqual(self.images, {})

    def test_error_30_requires_rescan_and_physical_reclaim(self):
        self.fail_first_reclaim = True
        runtime_import.install(self.package)
        self.assertIn(("xcrun", "simctl", "runtime", "scan-and-mount"), self.calls)
        self.assertFalse(self.asset.exists())

    def test_async_rescan_waits_for_registration_without_build_metadata(self):
        self.fail_first_reclaim = True
        pending = []
        polls = 0

        def command(*args, **kwargs):
            self.run_command(*args, **kwargs)
            if args == ("xcrun", "simctl", "runtime", "scan-and-mount"):
                pending.append(self.images.pop("rescanned"))

        def registry():
            nonlocal polls
            if pending:
                polls += 1
                if polls == 3:
                    # A Copying registration can have only a path initially.
                    self.images["copying"] = {"path": pending.pop()["path"]}
            return json.loads(json.dumps(self.images))

        with patch.object(runtime_import, "run", side_effect=command), \
                patch.object(runtime_import, "registry", side_effect=registry):
            runtime_import.install(self.package)
        self.assertIn(("sudo", "xcrun", "simctl", "runtime", "delete", "copying"), self.calls)
        self.assertFalse(self.asset.exists())

    def test_failed_cleanup_does_not_import(self):
        self.fail_all_deletes = True
        with self.assertRaises(RuntimeError):
            runtime_import.install(self.package)
        self.assertTrue(self.asset.exists())
        self.assertFalse(any(call[0] == "xcodebuild" for call in self.calls))

    def test_other_builds_and_architectures_are_preserved(self):
        other = self.root / "other"
        other.mkdir()
        self.images["other-build"] = self.image(other, build="23B86")
        self.images["other-architecture"] = self.image(other, architectures=["arm64", "x86_64"])
        runtime_import.install(self.package)
        self.assertEqual(set(self.images), {"other-build", "other-architecture"})
        self.assertTrue(other.exists())

    def test_existing_import_is_replaced_without_accumulating_duplicates(self):
        old = self.root / "Cryptex" / "Images" / "old"
        old.mkdir(parents=True)
        self.images["old-import"] = self.image(old)
        runtime_import.install(self.package)
        self.assertFalse(old.exists())
        self.assertIn(("sudo", "xcrun", "simctl", "runtime", "delete", "old-import"), self.calls)

    def test_unknown_bundle_is_rejected_before_deletion(self):
        self.metadata["CFBundleIdentifier"] = "unknown"
        self.write_metadata()
        with self.assertRaises(KeyError):
            runtime_import.install(self.package)
        self.assertEqual(self.calls, [])

    def test_legacy_dmg_uses_standard_import(self):
        self.package = self.root / "legacy.dmg"
        self.package.touch()
        runtime_import.install(self.package)
        self.assertEqual(self.calls, [("xcodebuild", "-importPlatform", str(self.package))])
        self.assertTrue(self.asset.exists())


if __name__ == "__main__":
    unittest.main()
