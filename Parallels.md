## Building Vanilla Image

First, start Parallels 16 for Desktop and create a `big-sur-vanilla` VM by just creating it from a recovery partition in the UI.

Use VM's UI to change some settings:

1. Disable Lock Screen. Preferences -> Lock Screen -> disable "Require Password" after 5.
2. Disable Screen Saver.
3. Enable Auto-Login. Users & Groups -> Login Options -> Automatic login -> admin.
4. Allow SSH. Sharing -> Remote Login
5. Open Safari. Preferences -> Advanced -> Show Developer menu. Develop -> Allow Remote Automation.
6. Run `sudo visudo` in Terminal, find `%admin ALL=(ALL) ALL` add `admin ALL=(ALL) NOPASSWD: ALL` to allow sudo without a password.
7. **optional** Disable SIP by [getting into Recov ery Mode](https://kb.parallels.com/cn/116526), `Utilities -> Terminal` and run `csrutil disable`.

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

To build an Xcode image (don't forget to setup `DEVPORTAL_EMAIL` and `DEVPORTAL_PASSWORD` since they are required by
[xcodes](https://github.com/RobotsAndPencils/xcodes#usage)):

```bash
packer build -only=parallels \
  -var xcode_version="12.4" \
  -var devportal_email="$DEVPORTAL_EMAIL" \
  -var devportal_password="$DEVPORTAL_PASSWORD" \
  templates/xcode.json
```
