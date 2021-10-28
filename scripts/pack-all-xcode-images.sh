#!/usr/bin/env bash

set -e

Xcodes=("12.4")

for Xcode in ${Xcodes[@]}; do
  mv "$HOME/Parallels/monterey-xcode-$Xcode/monterey-xcode-$Xcode.pvm" "$HOME/Parallels/monterey-xcode-$Xcode.pvm"
  rm -rf "$HOME/Parallels/monterey-xcode-$Xcode"
  prlctl register "$HOME/Parallels/monterey-xcode-$Xcode.pvm"
  prlctl set "monterey-xcode-$Xcode (1)" --name "monterey-xcode-$Xcode" || true
  prlctl start "monterey-xcode-$Xcode"
  sleep 180
  prlctl suspend "monterey-xcode-$Xcode"
  time prlctl pack "monterey-xcode-$Xcode"
done
