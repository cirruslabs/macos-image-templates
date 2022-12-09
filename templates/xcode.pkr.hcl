packer {
  required_plugins {
    tart = {
      version = ">= 0.5.4"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

variable "macos_version" {
  type =  string
  default = "ventura"
}

variable "xcode_version" {
  type =  string
  default = "14.2-RC"
}

source "tart-cli" "tart" {
  vm_base_name = "${var.macos_version}-base"
  vm_name      = "${var.macos_version}-xcode:${var.xcode_version}"
  cpu_count    = 4
  memory_gb    = 8
  disk_size_gb = 80
  ssh_password = "admin"
  ssh_username = "admin"
  ssh_timeout  = "120s"
}

build {
  sources = ["source.tart-cli.tart"]

  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "brew --version",
      "brew update",
      "brew upgrade",
      "brew install curl wget unzip zip ca-certificates",
      "sudo softwareupdate --install-rosetta --agree-to-license"
    ]
  }

  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "brew install --cask homebrew/cask-versions/temurin8",
      "brew install android-sdk android-ndk",
      "echo \"export ANDROID_HOME=/opt/homebrew/share/android-sdk\" >> ~/.zprofile",
      "echo \"export ANDROID_SDK_ROOT=/opt/homebrew/share/android-sdk\" >> ~/.zprofile",
      "echo \"export ANDROID_NDK_HOME=/opt/homebrew/share/android-ndk\" >> ~/.zprofile",
      "source ~/.zprofile",
      "sdkmanager --update",
      "yes | sdkmanager --licenses",
      "sdkmanager tools platform-tools emulator",
      "yes | sdkmanager \"platforms;android-30\" \"build-tools;30.0.2\" \"cmdline-tools;latest\"",
      "echo 'export PATH=$ANDROID_SDK_ROOT/tools:$ANDROID_SDK_ROOT/tools/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH' >> ~/.zprofile"
    ]
  }
  provisioner "shell" {
    inline = [
      "echo 'export PATH=/usr/local/bin/:$PATH' >> ~/.zprofile",
      "source ~/.zprofile",
      "wget --quiet https://github.com/RobotsAndPencils/xcodes/releases/latest/download/xcodes.zip",
      "unzip xcodes.zip",
      "rm xcodes.zip",
      "chmod +x xcodes",
      "sudo mkdir -p /usr/local/bin/",
      "sudo mv xcodes /usr/local/bin/xcodes",
      "xcodes version",
      "wget --quiet https://storage.googleapis.com/xcodes-cache/Xcode_${var.xcode_version}.xip",
      "xcodes install ${var.xcode_version} --experimental-unxip --path $PWD/Xcode_${var.xcode_version}.xip",
      "sudo rm -rf ~/.Trash/*",
      "xcodes select ${var.xcode_version}",
      "xcodebuild -downloadAllPlatforms",
      "xcodebuild -runFirstLaunch",
    ]
  }
  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "echo 'export FLUTTER_HOME=$HOME/flutter' >> ~/.zprofile",
      "echo 'export PATH=$HOME/flutter:$HOME/flutter/bin/:$HOME/flutter/bin/cache/dart-sdk/bin:$PATH' >> ~/.zprofile",
      "source ~/.zprofile",
      "git clone https://github.com/flutter/flutter.git $FLUTTER_HOME",
      "cd $FLUTTER_HOME",
      "git checkout stable",
      "flutter doctor --android-licenses",
      "flutter doctor",
      "flutter precache",
    ]
  }
  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "brew install libimobiledevice ideviceinstaller ios-deploy fastlane",
      "sudo gem update",
      "sudo gem install cocoapods",
      "sudo gem uninstall --ignore-dependencies ffi && sudo gem install ffi -- --enable-libffi-alloc"
    ]
  }
  # inspired by https://github.com/actions/runner-images/blob/fb3b6fd69957772c1596848e2daaec69eabca1bb/images/macos/provision/configuration/configure-machine.sh#L33-L61
  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "sudo security delete-certificate -Z FF6797793A3CD798DC5B2ABEF56F73EDC9F83A64 /Library/Keychains/System.keychain",
      "curl -o add-certificate.swift https://raw.githubusercontent.com/actions/runner-images/fb3b6fd69957772c1596848e2daaec69eabca1bb/images/macos/provision/configuration/add-certificate.swift",
      "swiftc add-certificate.swift",
      "curl -o AppleWWDRCAG3.cer https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer",
      "curl -o DeveloperIDG2CA.cer https://www.apple.com/certificateauthority/DeveloperIDG2CA.cer",
      "sudo ./add-certificate AppleWWDRCAG3.cer",
      "sudo ./add-certificate DeveloperIDG2CA.cer",
      "rm add-certificate* *.cer"
    ]
  }
  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "brew doctor",
      "flutter doctor"
    ]
  }
}
