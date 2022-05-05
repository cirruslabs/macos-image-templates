packer {
  required_plugins {
    tart = {
      version = ">= 0.3.1"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

variable "xcode_version" {
  type =  string
  default = "13.3.1"
}

source "tart-cli" "tart" {
  vm_base_name = "monterey-base"
  vm_name      = "monterey-xcode:${var.xcode_version}"
  cpu_count    = 4
  memory_gb    = 8
  disk_size_gb = 70
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
    ]
  }
  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "curl -s \"https://get.sdkman.io\" | bash",
      "source $HOME/.sdkman/bin/sdkman-init.sh",
      "sdk version",
      "curl --version",
      "echo 'sdkman_auto_answer=true' >> ~/.sdkman/etc/config",
      "echo 'sdkman_auto_complete=false' >> ~/.sdkman/etc/config",
      "echo 'sdkman_selfupdate_enable=false' >> ~/.sdkman/etc/config",
      "sdk install java 8.0.332-zulu || sdk install java 8.0.332-zulu",
      "echo \"source $HOME/.sdkman/bin/sdkman-init.sh\" >> ~/.zprofile",
    ]
  }
  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "brew install --cask android-sdk android-ndk",
      "echo \"export ANDROID_SDK_ROOT=/usr/local/share/android-sdk\" >> ~/.zprofile",
      "echo \"export ANDROID_NDK_HOME=/usr/local/share/android-ndk\" >> ~/.zprofile",
      "source ~/.zprofile",
      "sdkmanager --update",
      "yes | sdkmanager --licenses",
      "sdkmanager tools platform-tools emulator",
      "yes | sdkmanager \"platforms;android-30\" \"build-tools;30.0.2\"",
      "echo 'export PATH=$ANDROID_SDK_ROOT/tools:$ANDROID_SDK_ROOT/tools/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH' >> ~/.zprofile",
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
      "sudo xcodebuild -runFirstLaunch",
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
      "flutter doctor",
      "flutter precache",
    ]
  }
  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "brew install libimobiledevice ideviceinstaller ios-deploy fastlane",
      "sudo gem update",
      "sudo gem install cocoapods"
    ]
  }
}
