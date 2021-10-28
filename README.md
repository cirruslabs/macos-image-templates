# macOS Packer Templates for Cirrus CI

Repository with Packer templates to build VMs to use with [Cirrus CI](https://cirrus-ci.org/).

* `catalina-base` image has only `brew` pre-installed
* `catalina-xcode-N` image is based of `catalina-base` and has `Xcode N` with [`Flutter`](https://flutter.dev/) pre-installed
* `big-sur-base` image has only `brew` pre-installed
* `big-sur-xcode-N` image is based of `big-sur-base` and has `Xcode N` with [`Flutter`](https://flutter.dev/) pre-installed
* `monterey-base` image has only `brew` pre-installed
* `monterey-xcode-N` image is based of `monterey-base` and has `Xcode N` with [`Flutter`](https://flutter.dev/) pre-installed

See a full list of VMs available on Cirrus CI [here](https://cirrus-ci.org/guide/macOS/#list-of-available-images).

# Supported Virtualization Technologies

## Anka

Please see [`Anka.md`](Anka.md) for details on how to build Anka VMs.
