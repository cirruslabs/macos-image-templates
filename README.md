# osx-images

Packer templates to build [macOS Anka images](https://veertu.com/anka-technology/) to use in CI:

  * `catalina-base` image has only `brew` pre-installed
  * `catalina-xcode-11.5` image is based of `catalina-base` and has only `Xcode 11.5` pre-installed
  * `catalina-flutter` image is based of `catalina-xcode-11.5` and has only [`Flutter`](https://flutter.dev/) pre-installed

## Building Base Image

First, run `./scripts/install-anka-builder.sh` to install Anka builder for Packer.

To build the base image (you need to have `/Applications/Install macOS Catalina.app/` installed from App Store):

```bash
packer build templates/catalina-base.json
```

We also need to add a port forwarding rule so VMs based of `catalina-base` image can be SSHable:

```bash
anka modify catalina-base add port-forwarding --host-port 0 --guest-port 22 ssh
```

## Building Xcode Images

To build an Xcode image (don't forget to setup `FASTLANE_USER` and `FASTLANE_PASSWORD` since they are required by
[xcode-install](https://github.com/KrauseFx/xcode-install#usage)):

```bash
packer build -var xcode_version="11.5" \
  -var fastalne_user="$FASTLANE_USER" \
  -var fastlane_password="$FASTLANE_PASSWORD" \
  templates/catalina-xcode.json
```
