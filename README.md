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

Base images install a universal `TartMetalCapabilities.dylib` in `/usr/local/lib`.
It is built from the [vendored shim](data/tart-metal-capabilities), adapted from
Cua's MIT-licensed implementation. Its original license is installed in
`/usr/local/share/licenses/tart-metal-capabilities`.
Both Tart guest-agent launchd jobs enable it for themselves and their child
processes, including commands started with `tart exec`. Other login-session
processes keep their normal environment.

The default profile uses `TART_METAL_APPLE_FAMILY_MAX=1009` and
`TART_METAL_MAX_THREADGROUP_MEMORY=65536`. This is experimental and depends on
the host GPU, macOS versions, and workload; it is not physical GPU passthrough.
The host user running Tart must separately enable the unrestricted virtual-GPU
feature level while the VM is stopped:

```shell
defaults write com.apple.gpusw.ParavirtualizedGraphics ForceUnrestrictedDeviceFeatureLevel -bool true
```

Start the VM again after changing that preference. Each new process reads its
own configuration, so a command can override the default without restarting the
guest agent or affecting another command:

```shell
tart exec my-vm /usr/bin/env \
  DYLD_INSERT_LIBRARIES=/usr/local/lib/TartMetalCapabilities.dylib \
  TART_METAL_APPLE_FAMILY_MAX=1008 \
  /path/to/workload
```

Set `TART_METAL_APPLE_FAMILY_MAX=0` for stock capabilities. Setting the dylib path
explicitly keeps the override working through launcher programs that strip
inherited `DYLD_*` variables. The configuration is fixed when the workload
starts; changing an already-running process's environment does not reconfigure it.
To disable injection completely, remove the three Metal environment entries
from the guest's `org.cirruslabs.tart-guest-agent` and
`org.cirruslabs.tart-guest-daemon` launchd plists and reboot the guest.
Protected or hardened executables may reject or remove library injection.

## Release Cadence

Once a new version of Xcode is released, we will initiate a GitHub release which will automatically build and push
a new version of the `macos-{tahoe,sequoia}-xcode:N`. This generally happens the next weekend after a release.
Please watch this repository releases to get notified about new images.

## Update Cadence

Some of the images are regularly getting rebuild in order to update the pre-installed packages. 

[This workflow](.github/workflows/monthly.yml) defines images that are getting rebuilt monthly on the first Saturday of the month.
