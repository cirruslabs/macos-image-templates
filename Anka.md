## Building Base Image

First, download macOS from App Store to have a `*.app` installation in `/Applications` folder and create a vanilla VM to
base all other VMs from:

```bash
anka create --ram-size 8G --cpu-count 2 --disk-size 80G -a /Applications/Install\ macOS\ Big\ Sur.app monterey-vanilla
```

Then run `./scripts/install-anka-builder.sh` to install Anka builder for Packer.

To build the base image (you need to have `/Applications/Install macOS Big Sur.app/` installed from App Store):

```bash
packer build -only=anka templates/base.json
```

We also need to add a port forwarding rule so VMs based of `catalina-base` image can be SSHable:

```bash
anka modify monterey-base add port-forwarding --host-port 0 --guest-port 22 ssh
```

## Building Xcode Images

To build an Xcode image (don't forget to setup `DEVPORTAL_EMAIL` and `DEVPORTAL_PASSWORD` since they are required by
[xcodes](https://github.com/RobotsAndPencils/xcodes#usage)):

```bash
packer build -only=anka \
  -var xcode_version="12.3" \
  -var devportal_email="$DEVPORTAL_EMAIL" \
  -var devportal_password="$DEVPORTAL_PASSWORD" \
  templates/xcode.json
```
