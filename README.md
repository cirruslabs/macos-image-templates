## macOS Packer Templates for Cirrus CI

Repository with Packer templates to build [Tart VMs](https://github.com/cirruslabs/tart) to use with [Cirrus CI](https://cirrus-ci.org/guide/macOS/).

* `macos-{monterey,ventura}-vanilla` image nothing pre-installed
* `macos-{monterey,ventura}-base` image has only `brew` pre-installed
* `macos-{monterey,ventura}-xcode:N` image is based of `macos-{monterey,ventura}-base` and has `Xcode N` with [`Flutter`](https://flutter.dev/) pre-installed

See a full list of VMs available on Cirrus CI [here](https://github.com/orgs/cirruslabs/packages?tab=packages&q=macos-).

## Building Vanilla Image

First, create a `ventura-vanilla` VM from the latest available IPSW with following command:

```console
tart create --from-ipsw=latest --disk-size=25 ventura-vanilla
```

Start the VM and use UI to change some settings:

```console
tart run ventura-vanilla
```

1. Disable Lock Screen and Screen Saver. Preferences -> Lock Screen -> disable first three settings.
2. Enable Auto-Login. Users & Groups -> Automatic log in as... -> admin.
3. Allow SSH. General -> Sharing -> Remote Login & Screen Sharing
4. Display -> Advanced -> Prevent from sleeping
5. Open Safari. Preferences -> Advanced -> Show Developer menu. Develop -> Allow Remote Automation.
6. (Optional, depends on your needs) Disable SIP. Run `tart run --recovery ventura-vanilla` -> Options -> Utilities menu -> Terminal -> `csrutil disable`.
7. Enable passwordless `sudo`:
    1. Run `sudo visudo /private/etc/sudoers.d/admin-passwordless` in Terminal.
    2. Add `admin ALL = (ALL) NOPASSWD: ALL` to allow `sudo` without a password.
    3. `:wq` to write the file and quit.
    4. `sudo visudo -c` to verify your new file parsed OK.
    5. `sudo` some command to verify no password is needed.

Shutdown macOS.

## Building Base Image

```bash
packer build templates/base.pkr.hcl
```

## Building Xcode Images

```bash
packer build -var xcode_version="14-beta-5" templates/xcode.pkr.hcl
```
