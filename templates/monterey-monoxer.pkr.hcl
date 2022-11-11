packer {
  required_plugins {
    tart = {
      version = ">= 0.5.1"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

source "tart-cli" "tart" {
  vm_base_name = "monterey-vanilla"
  vm_name      = "monterey-monoxer"
  cpu_count    = 3
  memory_gb    = 14
  disk_size_gb = 100
  ssh_password = "admin"
  ssh_username = "admin"
  ssh_timeout  = "120s"
}

variable "gha_version" {
  type =  string
  default = "2.299.1"
}

build {
  sources = ["source.tart-cli.tart"]

  provisioner "shell" {
    inline = [
      "echo 'Disabling spotlight...'",
      "sudo mdutil -a -i off",
      "networksetup -setdnsservers Ethernet 8.8.8.8 8.8.4.4 1.1.1.1",
      "sudo softwareupdate --install-rosetta --agree-to-license"
    ]
  }

  provisioner "shell" {
    inline = [
      "cd $HOME",
      "mkdir actions-runner && cd actions-runner",
      "curl -O -L https://github.com/actions/runner/releases/download/v${var.gha_version}/actions-runner-osx-arm64-${var.gha_version}.tar.gz",
      "tar xzf ./actions-runner-osx-arm64-${var.gha_version}.tar.gz",
      "rm actions-runner-osx-arm64-${var.gha_version}.tar.gz"
    ]
  }

  provisioner "shell" {
    inline = [
      "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"",
      "echo \"export LANG=en_US.UTF-8\" >> ~/.zprofile",
      "echo 'eval \"$(/opt/homebrew/bin/brew shellenv)\"' >> ~/.zprofile",
      "echo \"export HOMEBREW_NO_AUTO_UPDATE=1\" >> ~/.zprofile",
      "echo \"export HOMEBREW_NO_INSTALL_CLEANUP=1\" >> ~/.zprofile",
      "source ~/.zprofile",
      "brew --version",
      "brew update"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo safaridriver --enable"
    ]
  }

  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "brew install xcodes aria2",
      "xcodes version",
      "xcodes install 14.1 --experimental-unxip",
      "xcodes select 14.1",
      "sudo xcodebuild -runFirstLaunch",
      "xcodes install 13.1.0 --experimental-unxip",
      "xcodes select 13.1.0",
      "sudo xcodebuild -runFirstLaunch"
    ]
  }

  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "brew install libimobiledevice ideviceinstaller ios-deploy fastlane"
    ]
  }

  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "brew tap monoxer/monoxer",
      "brew install carthage fastlane monoxer-cocoapods monoxer-rome swiftlint"
    ]
  }
}
