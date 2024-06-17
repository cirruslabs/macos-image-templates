## macOS Packer Templates for Tart

Repository with Packer templates to build macOS [Tart](https://tart.app/) virtual machines to use with [Cirrus Runners](https://cirrus-runners.app/),
[Cirrus CI](https://cirrus-ci.org/guide/macOS/) or [any other automation](https://tart.run/integrations/cirrus-cli/).

The following image variants are currently available:

* `macos-{sequoia,sonoma}-base` image has only `brew` pre-installed and the latest version of `macOS` available
* `macos-{sequoia,sonoma}-xcode:N` image is based on `macos-{sequoia,sonoma}-base` image and has `Xcode N` with [`Flutter`](https://flutter.dev/) pre-installed
* `macos-runner:sonoma` image is a variant of `xcode:N` with 3 latest versions of `Xcode` pre-installed and [`xcodes` tool](https://github.com/XcodesOrg/xcodes) to switch between them.

See a full list of VMs available [here](https://github.com/orgs/cirruslabs/packages?tab=packages&q=macos-).

## Release Cadence

Once a new version of Xcode is released, we will initiate a GitHub release which will automatically build and push
a new version of the `macos-{sequoia,sonoma}-xcode:N` image as well as `macos-runner:sonoma`. This generally happens within 24 hours
of a release. Please watch this repository releases to get notified about new images.

## Update Cadence

Some of the images are regularly getting rebuild in order to update the pre-installed packages. The following images are updated
monthly on the first Saturday of the month:

* `ghcr.io/cirruslabs/macos-{sequoia,sonoma}-base`
* `ghcr.io/cirruslabs/macos-sonoma-xcode:{16-beta,latest,15.4,15.3,15.2}`
* `ghcr.io/cirruslabs/macos-sequoia-xcode:{16-beta}`

Note that `ghcr.io/cirruslabs/macos-runner:sonoma` is updated every Sunday and this image is [optimised for startup](https://cirrus-runners.app/blog/2024/04/11/optimizing-startup-time-of-cirrus-runners/)
on Cirrus Runners and Cirrus CI services.