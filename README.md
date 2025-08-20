## macOS Packer Templates for Tart

Repository with Packer templates to build macOS [Tart](https://tart.run/) virtual machines to use with [Cirrus Runners](https://cirrus-runners.app/),
[Cirrus CI](https://cirrus-ci.org/guide/macOS/) or [any other automation](https://tart.run/integrations/cirrus-cli/).

The following image variants are currently available:

* `macos-{sequoia,sonoma}-base` image has only `brew` pre-installed and the latest version of `macOS` available
* `macos-{sequoia,sonoma}-xcode:N` image is based on `macos-{sequoia,sonoma}-base` image and has `Xcode N` with [`Flutter`](https://flutter.dev/) pre-installed
* `macos-runner:{sequoia,sonoma}` image is a variant of `xcode:N` with several versions of `Xcode` pre-installed and [`xcodes` tool](https://github.com/XcodesOrg/xcodes) to switch between them.

See a full list of VMs available [here](https://github.com/orgs/cirruslabs/packages?tab=packages&q=macos-).

## Release Cadence

Once a new version of Xcode is released, we will initiate a GitHub release which will automatically build and push
a new version of the `macos-sequoia-xcode:N`. This generally happens the next weekend after a release.
Please watch this repository releases to get notified about new images.

## Update Cadence

Some of the images are regularly getting rebuild in order to update the pre-installed packages. 

[This configuration file](.ci/cirrus.release.yml) defines images that are getting rebuilt monthly on the first Saturday of the month.
