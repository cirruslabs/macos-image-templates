packer {
  required_plugins {
    tart = {
      version = ">= 1.12.0"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

variable "macos_version" {
  type = string
}

variable "xcode_version" {
  type = list(string)
}

variable "additional_ios_builds" {
  type = list(string)
  default = []
}

variable "expected_runtimes_file" {
  type    = string
  default = ""
  description = "Path to file containing expected simulator runtimes. If empty, runtime verification is skipped."
}

variable "tag" {
  type = string
  default = ""
}

variable "disk_size" {
  type = number
  default = 120
}

variable "disk_free_mb" {
  type = number
  default = 15000
}

variable "android_sdk_tools_version" {
  type    = string
  default = "11076708" # https://developer.android.com/studio#command-line-tools-only
}

source "tart-cli" "tart" {
  vm_base_name = "ghcr.io/cirruslabs/macos-${var.macos_version}-base:latest"
  // use tag or the last element of the xcode_version list
  vm_name      = "${var.macos_version}-xcode:${var.tag != "" ? var.tag : var.xcode_version[0]}"
  cpu_count    = 4
  memory_gb    = 8
  disk_size_gb = var.disk_size
  headless     = true
  ssh_password = "admin"
  ssh_username = "admin"
  ssh_timeout  = "120s"
}

locals {
  xcode_install_provisioners = [
    for version in reverse(sort(var.xcode_version)) : {
      type = "shell"
      inline = [
        "source ~/.zprofile",
        "sudo xcodes install ${version} --experimental-unxip --path /Users/admin/Downloads/Xcode_${version}.xip --select --empty-trash",
        // get selected xcode path, strip /Contents/Developer and move to GitHub compatible locations
        "INSTALLED_PATH=$(xcodes select -p)",
        "CONTENTS_DIR=$(dirname $INSTALLED_PATH)",
        "APP_DIR=$(dirname $CONTENTS_DIR)",
        "sudo mv $APP_DIR /Applications/Xcode_${version}.app",
        "sudo xcode-select -s /Applications/Xcode_${version}.app",
        "xcodebuild -downloadAllPlatforms",
        "xcodebuild -runFirstLaunch",
      ]
    }
  ]
}

build {
  sources = ["source.tart-cli.tart"]

  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "brew --version",
      "brew update",
      "brew upgrade",
    ]
  }

  // Re-install the GitHub Actions runner
  provisioner "shell" {
    script = "scripts/install-actions-runner.sh"
  }

  // make sure our workaround from base is still valid
  provisioner "shell" {
    inline = [
      "sudo ln -s /Users/admin /Users/runner || true"
    ]
  }

  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "brew install openjdk@17",
      "echo 'export PATH=\"/opt/homebrew/opt/openjdk@17/bin:$PATH\"' >> ~/.zprofile",
      "echo 'export ANDROID_HOME=$HOME/android-sdk' >> ~/.zprofile",
      "echo 'export ANDROID_SDK_ROOT=$ANDROID_HOME' >> ~/.zprofile",
      "echo 'export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator' >> ~/.zprofile",
      "source ~/.zprofile",
      "wget -q https://dl.google.com/android/repository/commandlinetools-mac-${var.android_sdk_tools_version}_latest.zip -O android-sdk-tools.zip",
      "mkdir -p $ANDROID_HOME/cmdline-tools/",
      "unzip -q android-sdk-tools.zip -d $ANDROID_HOME/cmdline-tools/",
      "rm android-sdk-tools.zip",
      "mv $ANDROID_HOME/cmdline-tools/cmdline-tools $ANDROID_HOME/cmdline-tools/latest",
      "yes | sdkmanager --licenses",
      "yes | sdkmanager 'platform-tools' 'platforms;android-35' 'build-tools;35.0.0' 'ndk;27.2.12479018'"
    ]
  }

  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "brew install libimobiledevice ideviceinstaller ios-deploy carthage",
      "brew install xcbeautify",
      "rbenv global 3.3.8", # fastlane conflicts with 3.4.0+ https://github.com/fastlane/fastlane/issues/29527
      "gem update",
      "gem install fastlane",
      "gem install cocoapods",
      "gem install xcpretty",
      "gem uninstall --ignore-dependencies ffi && gem install ffi -- --enable-libffi-alloc"
    ]
  }

  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "brew install xcodesorg/made/xcodes",
      "xcodes version",
    ]
  }

  provisioner "file" {
    sources      = [ for version in var.xcode_version : pathexpand("~/XcodesCache/Xcode_${version}.xip")]
    destination = "/Users/admin/Downloads/"
  }

  // iterate over all Xcode versions and install them
  // select the latest one as the default
  dynamic "provisioner" {
    for_each = local.xcode_install_provisioners
    labels = ["shell"]
    content {
      inline = provisioner.value.inline
    }
  }

  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "sudo xcodes select '${var.xcode_version[0]}'",
    ]
  }

  provisioner "shell" {
    inline = concat(
      ["source ~/.zprofile"],
      [
        for runtime in var.additional_ios_builds : "xcodebuild -downloadPlatform iOS -buildVersion ${runtime}"
      ]
    )
  }

  // Copy expected runtimes file if provided
  dynamic "provisioner" {
    for_each = var.expected_runtimes_file != "" ? [1] : []
    labels = ["file"]
    content {
      source      = var.expected_runtimes_file
      destination = "/Users/admin/runtimes.expected.txt"
    }
  }

  // Verify simulator runtimes match expected list if file was provided
  dynamic "provisioner" {
    for_each = var.expected_runtimes_file != "" ? [1] : []
    labels = ["shell"]
    content {
      inline = [
        "source ~/.zprofile",
        "xcrun simctl list runtimes > /Users/admin/runtimes.actual.txt",
        "diff -q /Users/admin/runtimes.actual.txt /Users/admin/runtimes.expected.txt || (echo 'Simulator runtimes do not match expected list' && cat /Users/admin/runtimes.actual.txt && exit 1)",
        "rm /Users/admin/runtimes.actual.txt /Users/admin/runtimes.expected.txt"
      ]
    }
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

  # useful utils for mobile development
  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "brew install graphicsmagick imagemagick",
      "brew install wix/brew/applesimutils",
      "brew install gnupg"
    ]
  }

  # inspired by https://github.com/actions/runner-images/blob/fb3b6fd69957772c1596848e2daaec69eabca1bb/images/macos/provision/configuration/configure-machine.sh#L33-L61
  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "curl -o AppleWWDRCAG3.cer https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer",
      "curl -o DeveloperIDG2CA.cer https://www.apple.com/certificateauthority/DeveloperIDG2CA.cer",
      "curl -o add-certificate.swift https://raw.githubusercontent.com/actions/runner-images/fb3b6fd69957772c1596848e2daaec69eabca1bb/images/macos/provision/configuration/add-certificate.swift",
      "swiftc -suppress-warnings add-certificate.swift",
      "sudo ./add-certificate AppleWWDRCAG3.cer",
      "sudo ./add-certificate DeveloperIDG2CA.cer",
      "rm add-certificate* *.cer"
    ]
  }

  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "flutter doctor"
    ]
  }

  // check there is at least 15GB of free space and fail if not
  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "df -h",
      "export FREE_MB=$(df -m | awk '{print $4}' | head -n 2 | tail -n 1)",
      "[[ $FREE_MB -gt ${var.disk_free_mb} ]] && echo OK || exit 1"
    ]
  }

  // some other health checks
  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "test -d /Users/runner"
    ]
  }

  # Disable apsd[1][2] daemon as it causes high CPU usage after boot
  #
  # [1]: https://iboysoft.com/wiki/apsd-mac.html
  # [2]: https://discussions.apple.com/thread/4459153
  provisioner "shell" {
    inline = [
      "sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.apsd.plist"
    ]
  }

  # Compatibility with GitHub Actions Runner Images, where
  # /usr/local/bin belongs to the default user. Also see [2].
  #
  # [1]: https://github.com/actions/runner-images/blob/6bbddd20d76d61606bea5a0133c950cc44c370d3/images/macos/scripts/build/configure-machine.sh#L96
  # [2]: https://github.com/actions/runner-images/discussions/7607
  provisioner "shell" {
    inline = [
      "sudo chown admin /usr/local/bin"
    ]
  }

  # Wait for the "update_dyld_sim_shared_cache" process[1][2] to finish
  # to avoid wasting CPU cycles after boot
  #
  # [1]: https://apple.stackexchange.com/questions/412101/update-dyld-sim-shared-cache-is-taking-up-a-lot-of-memory
  # [2]: https://stackoverflow.com/a/68394101/9316533
  provisioner "shell" {
    inline = [
      "sleep 1800"
    ]
  }

  // Install setup-info-generator
  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "brew install cirruslabs/cli/setup-info-generator"
    ]
  }

  // Copy setup info template
  provisioner "file" {
    source      = "data/setup-info-template.json"
    destination = "~/setup-info-template.json"
  }

  // Generate setup info
  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "cat ~/setup-info-template.json | setup-info-generator > ~/actions-runner/.setup_info",
      "rm ~/setup-info-template.json"
    ]
  }
}
