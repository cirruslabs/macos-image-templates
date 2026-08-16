## macOS Packer Templates for Tart

Repository with Packer templates to build macOS [Tart](https://tart.run/) virtual machines to use with self-hosted
GitHub Actions runners, [Cirrus Runners](https://cirrus-runners.app/) or [any other automation](https://tart.run/integrations/cirrus-cli/).

The following image variants are currently available:

* `macos-{golden-gate,tahoe,sequoia,sonoma}-vanilla` — a vanilla macOS installation with helpful tweaks such as auto-login, but no additional software preinstalled
* `macos-{golden-gate,tahoe,sequoia,sonoma}-base` — based on `macos-{golden-gate,tahoe,sequoia,sonoma}-vanilla` image, it comes with `brew` and [other useful software](https://github.com/cirruslabs/macos-image-templates/blob/main/templates/base.pkr.hcl) pre-installed, but without Xcode
* `macos-{tahoe,sequoia,sonoma}-xcode:N` — based on `macos-{tahoe,sequoia,sonoma}-base` image and has `Xcode N` with [`Flutter`](https://flutter.dev/) pre-installed
* `macos-runner:{tahoe,sequoia,sonoma}` — a variant of `xcode:N` with several versions of `Xcode` pre-installed and [`xcodes` tool](https://github.com/XcodesOrg/xcodes) to switch between them.

See a full list of VMs available [here](https://github.com/orgs/cirruslabs/packages?tab=packages&q=macos-).

## Metal capabilities

Base images include the experimental [Tart Metal shim](data/tart-metal-capabilities),
based on [the Lume team's work](https://github.com/trycua/cua/blob/main/blog/gpu-passthrough-macos-vms.md). The guest agent enables
`/usr/local/lib/TartMetalCapabilities.dylib` with Apple family 9 (`1009`) and
64 KiB of threadgroup memory. Commands inherit these defaults automatically:

```shell
tart exec my-vm /path/to/workload
```

Before starting the VM, enable unrestricted virtual-GPU features on the host
as the user running Tart:

```shell
defaults write com.apple.gpusw.ParavirtualizedGraphics ForceUnrestrictedDeviceFeatureLevel -bool true
```

Restart an already-running VM after changing that preference. To override the
family for one command:

```shell
tart exec my-vm /usr/bin/env \
  DYLD_INSERT_LIBRARIES=/usr/local/lib/TartMetalCapabilities.dylib \
  TART_METAL_APPLE_FAMILY_MAX=1008 \
  /path/to/workload
```

Use `TART_METAL_APPLE_FAMILY_MAX=0` for stock capabilities. The explicit dylib
path handles launchers that strip inherited `DYLD_*` variables; it is not needed
for direct commands. Each new process gets its own settings. To disable injection
entirely, remove the Metal environment entries from both guest-agent launchd
plists and reboot the guest. Protected executables may reject injection, and
GPU support depends on the host, guest, and workload.

## Release Cadence

Once a new version of Xcode is released, we will initiate a GitHub release which will automatically build and push
a new version of the `macos-{tahoe,sequoia}-xcode:N`. This generally happens the next weekend after a release.
Please watch this repository releases to get notified about new images.

## Update Cadence

Some of the images are regularly getting rebuild in order to update the pre-installed packages. 

[This workflow](.github/workflows/monthly.yml) defines images that are getting rebuilt monthly on the first Saturday of the month.
