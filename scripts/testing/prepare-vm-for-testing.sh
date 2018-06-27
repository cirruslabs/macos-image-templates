#!/usr/bin/env bash

set -e

ANKA_VERSION=$(anka version | egrep -o '([0-9].)+[0-9]')

echo "Creating high-sierra-perf-$ANKA_VERSION VM for testing..."
#anka create --ram-size 4G --cpu-count 2 --disk-size 60G --app /Applications/Install\ macOS\ High\ Sierra.app high-sierra-perf-$ANKA_VERSION
anka run --volume $PWD/scripts/testing high-sierra-perf-$ANKA_VERSION bash install-dependencies-for-tests.sh