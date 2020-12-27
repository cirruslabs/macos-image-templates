## Building Base Image

First, download macOS from App Store to have a `*.app` installation in `/Applications` folder.

Then run `./scripts/install-anka-builder.sh` to install Anka builder for Packer.

To build the base image (you need to have `/Applications/Install macOS Big Sur.app/` installed from App Store):

```bash
packer build -only=anka templates/big-sur-base.json
```

We also need to add a port forwarding rule so VMs based of `catalina-base` image can be SSHable:

```bash
anka modify big-sur-base add port-forwarding --host-port 0 --guest-port 22 ssh
```

## Building Xcode Images

To build an Xcode image (don't forget to setup `FASTLANE_USER` and `FASTLANE_PASSWORD` since they are required by
[xcode-install](https://github.com/KrauseFx/xcode-install#usage)):

```bash
packer build -only=anka \
  -var xcode_version="12.3" \
  -var fastlane_user="$FASTLANE_USER" \
  -var fastlane_password="$FASTLANE_PASSWORD" \
  templates/big-sur-xcode.json
```
