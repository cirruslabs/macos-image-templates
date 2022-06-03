## macOS Packer Templates for Cirrus CI

Repository with Packer templates to build VMs to use with [Cirrus CI](https://cirrus-ci.org/guide/macOS/).

* `macos-monterey-vanilla` image nothing pre-installed
* `macos-monterey-base` image has only `brew` pre-installed
* `macos-monterey-xcode:N` image is based of `macos-monterey-base` and has `Xcode N` with [`Flutter`](https://flutter.dev/) pre-installed

See a full list of VMs available on Cirrus CI [here](https://github.com/orgs/cirruslabs/packages?tab=packages&q=macos-).

## Building Vanilla Image

First, create a `monterey-vanilla` VM from the latest available IPSW with following command:

```console
tart create --from-ipsw=latest --disk-size=25 monterey-vanilla
```

Start the VM and use UI to change some settings:

```console
tart run monterey-vanilla
```

1. Allow SSH. Sharing -> Remote Login
1a. Check `Allow full disk access for remote users`
2. Disable Screen Saver. Desktop & Screen Saver -> Screen Saver
3. Enable Auto-Login. Users & Groups -> Login Options -> Automatic login -> admin.
4. Optionally disable SIP. Run `tart run --recovery monterey-vanilla` -> Options -> Utilities menu -> Terminal -> `csrutil disable`.

From this point you can either use the scripted `initial_install.sh` or you can follow the manual steps below (that do the same as the script)

The script assumes that your admin username is `admin`, change as necessary

It will ask you to enter your password a few times (unavoidable)

To use the script, from your local machine:

```console
scp scripts/initial_install.sh admin@$(tart ip monterey-vanilla):
ssh admin@$(tart ip monterey-vanilla)
./initial_install.sh
```

Optional: do the work in `initial_install.sh` manually:

1. Disable Lock Screen. Preferences -> Security  & Privacy -> disable "Require Password" after 5.
3. Power -> Turn display off -> Never & Prevent from sleeping
4. Open Safari. Preferences -> Advanced -> Show Developer menu. Develop -> Allow Remote Automation.
5. Run `sudo visudo` in Terminal, find `%admin ALL=(ALL) ALL` add `admin ALL=(ALL) NOPASSWD: ALL` to allow sudo without a password.

Shutdown macOS.

## Building Base Image

```bash
packer build templates/base.pkr.hcl
```

## Building Xcode Images

```bash
packer build -var xcode_version="13.4" templates/xcode.pkr.hcl
```
