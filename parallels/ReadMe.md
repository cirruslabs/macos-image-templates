# Parallels-based images

Packer templates to build [macOS Parallels images](https://veertu.com/anka-technology/) to use in CI:

* `big-sur-base` image has only `brew` pre-installed
* `big-sur-xcode-12.3` image is based of `big-sur-base` and has `Xcode 12.3` with [`Flutter`](https://flutter.dev/) pre-installed

## Building Vanilla Image

First, start Parallels 16 for Desktop and create a `big-sur-vanilla` VM by just creating it from a recovery partition in UI.

Use UI to change some settings:

1. Disable Lock Screen. Preferences -> Lock Screen -> disable "Require Password" after 5.
2. Disable Screen Saver.
3. Enable Auto-Login. Users & Groups -> Login Options -> Automatic login -> admin.
4. Allow SSH. Sharing -> Remote Login
5. Open Safari. Preferences -> Advanced -> Show Developer menu. Develop -> Allow Remote Automation.
6. Run `sudo visudo` in Terminal, find `%admin ALL=(ALL) ALL` add `admin ALL=(ALL) NOPASSWD: ALL` to allow sudo without a password.

Shutdown macOS.

## Building Base Image

```bash
packer build templates/big-sur-base.json
```

If you are getting `prlctl error: Failed to register the VM: "big-sur-vanilla" is already registered.` error, run:

```bash
 prlctl unregister big-sur-vanilla
 ```

## Building Xcode Images

To build an Xcode image (don't forget to setup `FASTLANE_USER` and `FASTLANE_PASSWORD` since they are required by
[xcode-install](https://github.com/KrauseFx/xcode-install#usage)):

```bash
packer build -var xcode_version="12.3" \
  -var fastlane_user="$FASTLANE_USER" \
  -var fastlane_password="$FASTLANE_PASSWORD" \
  templates/big-sur-xcode.json
```
