#!/usr/bin/env bash

set -e

BUILDER_VERSION=1.0.1

curl -L -o packer-builder-veertu-anka.tar.gz \
     https://github.com/buildkite/packer-builder-veertu-anka/releases/download/v${BUILDER_VERSION}/packer-builder-veertu-anka_${BUILDER_VERSION}_darwin_amd64.tar.gz

mkdir -p build
tar -xvzf packer-builder-veertu-anka.tar.gz -C build
mv build/packer-builder-veertu-anka packer-builder-veertu-anka
rm -rf build packer-builder-veertu-anka.tar.gz