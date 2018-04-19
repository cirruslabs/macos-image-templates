# osx-images

Packer templates to build [Mac OS Anka images](https://veertu.com/anka-technology/) to use in CI.

# Building

First, run `./scripts/install-anka-builder.sh` to install Anka builder for Packer.

To build the base image (you need to have `/Applications/Install macOS High Sierra.app/` installed from App Store):

```bash
packer build templates/osx-10.13-base.json
```

To build an Xcode image (don't forget to setup `FASTLANE_USER` and `FASTLANE_PASSWORD` since they are required by
[xcode-install](https://github.com/KrauseFx/xcode-install#usage)):

```bash
packer build -var xcode_version="9.3" templates/osx-10.13-xcode.json
```