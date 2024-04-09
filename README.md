## macOS Packer Templates for Tart

This repository contains [Packer] templates to build [Tart VMs] to use with
[Cirrus Runners] and [Cirrus CI].

- `macos-{ventura,sonoma}-base` image has only `brew` pre-installed
- `macos-{ventura,sonoma}-xcode:N` image is based on
  `macos-{monterey,ventura}-base` image and has `Xcode N` with latest stable
  [`Flutter`](https://flutter.dev/)[^1] pre-installed

See a full list of VMs available [here][vm_list].

## Building Vanilla Image

To build `macos-sonoma-vanilla`:

```console
packer build templates/vanilla-sonoma.pkr.hcl
```

Optionally, SIP can be disabled for each image by running the following commands:

```console
packer build -var vm_name=sonoma-vanilla templates/disable-sip.pkr.hcl
```

## Building Base Image

```console
packer build -var macos_version=sonoma templates/base.pkr.hcl
```

## Building Xcode Image

```console
packer build -var macos_version=sonoma -var xcode_version=15.3 templates/xcode.pkr.hcl
```

[^1]:
    Latest stable Flutter version excluding PATCH versions. For example, as
    of Apr 9th 2024, the latest stable Flutter is 3.19.5, so the Flutter version
    pre-installed will be 3.19.0.

[Packer]: https://github.com/hashicorp/packer
[Tart VMs]: https://github.com/cirruslabs/tart
[Cirrus Runners]: https://tart.run/integrations/github-actions
[Cirrus CI]: https://cirrus-ci.org/guide/macOS
[vm_list]: https://github.com/orgs/cirruslabs/packages?tab=packages&q=macos-
