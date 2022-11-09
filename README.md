## macOS Packer Templates for Cirrus CI

Repository with Packer templates to build [Tart VMs](https://github.com/cirruslabs/tart) to use with [Cirrus CI](https://cirrus-ci.org/guide/macOS/).

* `macos-{monterey,ventura}-vanilla` image has nothing pre-installed
* `macos-{monterey,ventura}-base` image has only `brew` pre-installed
* `macos-{monterey,ventura}-xcode:N` image is based on `macos-{monterey,ventura}-base` image and has `Xcode N` with [`Flutter`](https://flutter.dev/) pre-installed

See a full list of VMs available on Cirrus CI [here](https://github.com/orgs/cirruslabs/packages?tab=packages&q=macos-).

## Building Vanilla Image

To build `macos-monterey-vanilla`:

```
packer build templates/vanilla-monterey.pkr.hcl
```

To build `macos-ventura-vanilla`:

```
packer build templates/vanilla-ventura.pkr.hcl
```

Optionally, SIP can be disabled for each image by running the following commands:

```
packer build -var vm_name=monterey-vanilla templates/disable-sip.pkr.hcl
packer build -var vm_name=ventura-vanilla templates/disable-sip.pkr.hcl
```

## Building Monoxer Image

```bash
packer build templates/monterey-monoxer.pkr.hcl
packer build templates/ventura-monoxer.pkr.hcl
```
