## Building Vanilla Image

First, start Parallels 16 for Desktop and create a `big-sur-vanilla` VM by just creating it from a recovery partition in the UI.

Use VM's UI to change some settings:

1. Disable Lock Screen. Preferences -> Lock Screen -> disable "Require Password" after 5.
2. Disable Screen Saver.
3. Enable Auto-Login. Users & Groups -> Login Options -> Automatic login -> admin.
4. Allow SSH. Sharing -> Remote Login
5. Open Safari. Preferences -> Advanced -> Show Developer menu. Develop -> Allow Remote Automation.
6. Run `sudo visudo` in Terminal, find `%admin ALL=(ALL) ALL` add `admin ALL=(ALL) NOPASSWD: ALL` to allow sudo without a password.

Shutdown macOS.

Also change some VM settings:

1. Security -> Isolate VM from Mac.
2. Change any other settings.

## Building Base Image

```bash
packer build -only=parallels templates/base.json
```

If you are getting `prlctl error: Failed to register the VM: "big-sur-vanilla" is already registered.` error, run:

```bash
prlctl unregister big-sur-vanilla
```

## Building Xcode Images

To build an Xcode image (don't forget to setup `FASTLANE_USER` and `FASTLANE_PASSWORD` since they are required by
[xcode-install](https://github.com/KrauseFx/xcode-install#usage)):

```bash
packer build -only=parallels \
  -var xcode_version="12.3" \
  -var fastlane_user="$FASTLANE_USER" \
  -var fastlane_password="$FASTLANE_PASSWORD" \
  templates/xcode.json
```
