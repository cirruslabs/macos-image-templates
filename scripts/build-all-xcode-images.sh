#!/usr/bin/env bash

set -e

Xcodes=("12.4")

for Xcode in ${Xcodes[@]}; do
  packer build -only=parallels \
    -var xcode_version=$Xcode \
    -var devportal_email="$DEVPORTAL_EMAIL" \
    -var devportal_password="$DEVPORTAL_PASSWORD" \
    templates/xcode.json
done