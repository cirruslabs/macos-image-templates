#!/bin/bash

# Set shell options to enable fail-fast behavior
#
# * -e: fail the script when an error occurs or command fails
# * -u: fail the script when attempting to reference unset parameters
# * -o pipefail: by default an exit status of a pipeline is that of its
#                last command, this fails the pipe early if an error in
#                any of its commands occurs
#
set -euo pipefail

source ~/.zprofile
brew install jq

DOWNLOAD_URL=$(curl -sS 'https://api.github.com/repos/actions/runner/releases/latest' | jq --raw-output '.assets[] | select(.name | test("actions-runner-osx-arm64-[0-9.]+.tar.gz")) | .browser_download_url')

rm -rf actions-runner && mkdir actions-runner && cd actions-runner

wget -O - "${DOWNLOAD_URL}" | tar xz
