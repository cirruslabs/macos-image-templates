## macOS Packer Templates for Tart

Repository with Packer templates to build macOS [Tart](https://tart.run/) virtual machines to use with [Cirrus Runners](https://cirrus-runners.app/),
[Cirrus CI](https://cirrus-ci.org/guide/macOS/) or [any other automation](https://tart.run/integrations/cirrus-cli/).

The following image variants are currently available:

* `macos-{tahoe,sequoia,sonoma}-vanilla` — a vanilla macOS installation with helpful tweaks such as auto-login, but no additional software preinstalled
* `macos-{tahoe,sequoia,sonoma}-base` — based on `macos-{tahoe,sequoia,sonoma}-vanilla` image, it comes with `brew` and [other useful software](https://github.com/cirruslabs/macos-image-templates/blob/main/templates/base.pkr.hcl) pre-installed, but without XCode
* `macos-{tahoe,sequoia,sonoma}-xcode:N` — based on `macos-{tahoe,sequoia,sonoma}-base` image and has `Xcode N` with [`Flutter`](https://flutter.dev/) pre-installed
* `macos-runner:{tahoe,sequoia,sonoma}` — a variant of `xcode:N` with several versions of `Xcode` pre-installed and [`xcodes` tool](https://github.com/XcodesOrg/xcodes) to switch between them.

See a full list of VMs available [here](https://github.com/orgs/cirruslabs/packages?tab=packages&q=macos-).

## Release Cadence

Once a new version of Xcode is released, we will initiate a GitHub release which will automatically build and push
a new version of the `macos-{tahoe,sequoia}-xcode:N`. This generally happens the next weekend after a release.
Please watch this repository releases to get notified about new images.

## Update Cadence

Some of the images are regularly getting rebuild in order to update the pre-installed packages. 

[This configuration file](.ci/cirrus.release.yml) defines images that are getting rebuilt monthly on the first Saturday of the month.
