## macOS Packer Templates for Cirrus CI

Repository with Packer templates to build [Tart VMs](https://github.com/cirruslabs/tart) to use with [Cirrus CI](https://cirrus-ci.org/guide/macOS/).

* `macos-{monterey,ventura,sonoma}-vanilla` image has nothing pre-installed
* `macos-{monterey,ventura,sonoma}-base` image has only `brew` pre-installed
* `macos-{monterey,ventura,sonoma}-xcode:N` image is based on `macos-{monterey,ventura}-base` image and has `Xcode N` with [`Flutter`](https://flutter.dev/) pre-installed

See a full list of VMs available on Cirrus CI [here](https://github.com/orgs/cirruslabs/packages?tab=packages&q=macos-).

## Building Vanilla Image

To build `macos-sonoma-vanilla`:

```bash
packer build templates/vanilla-sonoma.pkr.hcl
```

Optionally, SIP can be disabled for each image by running the following commands:

```bash
packer build -var vm_name=sonoma-vanilla templates/disable-sip.pkr.hcl
```

## Building Base Image

```bash
packer build -var-file="variables.pkrvars.hcl" templates/base.pkr.hcl
```

## Building Xcode Image

```bash
packer build -var-file="variables.pkrvars.hcl" templates/xcode.pkr.hcl
```
