#!/usr/bin/env bash

yes '' | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
echo "export PATH=/usr/local/bin:$PATH" >> ~/.profile

brew update
brew install node@8
brew link --force node@8