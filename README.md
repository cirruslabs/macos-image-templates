# osx-images

Packer templates to build [Mac OS Anka images](https://veertu.com/anka-technology/) to use in CI:

  * `high-sierra-base` image has only `brew` pre-installed
  * `high-sierra-xcode-9.4` image is based of `high-sierra-base` and has only `Xcode 9.4` pre-installed

# Building Base Image

First, run `./scripts/install-anka-builder.sh` to install Anka builder for Packer.

To build the base image (you need to have `/Applications/Install macOS High Sierra.app/` installed from App Store):

```bash
packer build templates/high-sierra-base.json
```

We also need to add a port forwarding rule so VMs based of `osx-10.13-base` image can be SSHable:

```bash
anka modify high-sierra-base add port-forwarding --host-port 0 --guest-port 22 --protocol tcp ssh
```

# Building Xcode Images

To build an Xcode image (don't forget to setup `FASTLANE_USER` and `FASTLANE_PASSWORD` since they are required by
[xcode-install](https://github.com/KrauseFx/xcode-install#usage)):

```bash
packer build -var xcode_version="9.4" templates/high-sierra-xcode.json
```