#!/usr/bin/env bash

set -e

Xcodes=("12.4")

for Xcode in ${Xcodes[@]}; do
  mv "$HOME/Parallels/big-sur-xcode-$Xcode/big-sur-xcode-$Xcode.pvm" "$HOME/Parallels/big-sur-xcode-$Xcode.pvm"
  rm -rf "$HOME/Parallels/big-sur-xcode-$Xcode"
  prlctl register "$HOME/Parallels/big-sur-xcode-$Xcode.pvm"
  prlctl set "big-sur-xcode-$Xcode (1)" --name "big-sur-xcode-$Xcode" || true
  prlctl start "big-sur-xcode-$Xcode"
  sleep 180
  prlctl suspend "big-sur-xcode-$Xcode"
  time prlctl pack "big-sur-xcode-$Xcode"
done