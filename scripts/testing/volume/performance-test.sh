#!/usr/bin/env bash

set -e

mkdir -p puppeteer
rm -rf puppeteer
git clone https://github.com/GoogleChrome/puppeteer.git

cd puppeteer
npm install --unsafe-perm
npm run lint
npm run coverage
npm run test-doclint

cd ..
rm -rf puppeteer