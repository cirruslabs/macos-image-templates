## Building Vanilla Image

First, create a `monterey-vanilla` VM from the latest available IPSW with following command:

```console
tart create --from-ipsw=latest monterey-vanilla
```

Start the VM and use UI to change some settings:

```console
tart run monterey-vanilla
```

1. Disable Lock Screen. Preferences -> Lock Screen -> disable "Require Password" after 5.
2. Disable Screen Saver.
3. Enable Auto-Login. Users & Groups -> Login Options -> Automatic login -> admin.
4. Allow SSH. Sharing -> Remote Login
5. Open Safari. Preferences -> Advanced -> Show Developer menu. Develop -> Allow Remote Automation.
6. Run `sudo visudo` in Terminal, find `%admin ALL=(ALL) ALL` add `admin ALL=(ALL) NOPASSWD: ALL` to allow sudo without a password.

Shutdown macOS.

## Building Base Image

```bash
packer build -only=tart templates/base.json
```

## Building Xcode Images

```bash
packer build -only=tart \
  -var xcode_version="13.3" \
  templates/xcode.json
```
