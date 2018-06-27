#!/usr/bin/env bash

ANKA_VERSION=$(anka version | egrep -o '([0-9].)+[0-9]')

time anka run --volume $PWD/scripts/testing/volume high-sierra-perf-$ANKA_VERSION ./performance-test.sh