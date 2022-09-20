packer {
  required_plugins {
    tart = {
      version = ">= 0.5.1"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

variable "macos_version" {
  type =  string
  default = "ventura"
}

variable "gha_version" {
  type =  string
  default = "2.296.1"
}

source "tart-cli" "tart" {
  vm_base_name = "ghcr.io/cirruslabs/macos-${var.macos_version}-vanilla:latest"
  vm_name      = "${var.macos_version}-base"
  cpu_count    = 4
  memory_gb    = 8
  disk_size_gb = 40
  ssh_password = "admin"
  ssh_username = "admin"
  ssh_timeout  = "120s"
}

build {
  sources = ["source.tart-cli.tart"]

  provisioner "shell" {
    inline = [
      "echo 'Disabling spotlight...'",
      "sudo mdutil -a -i off",
    ]
  }
  provisioner "shell" {
    inline = [
      "cd $HOME",
      "mkdir actions-runner && cd actions-runner",
      "curl -O -L https://github.com/actions/runner/releases/download/v${var.gha_version}/actions-runner-osx-arm64-${var.gha_version}.tar.gz",
      "tar xzf ./actions-runner-osx-arm64-${var.gha_version}.tar.gz",
      "rm actions-runner-osx-arm64-${var.gha_version}.tar.gz",
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
      "brew update",
      "brew install wget cmake gcc",
    ]
  }
  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "brew install rbenv",
      "echo 'if which rbenv > /dev/null; then eval \"$(rbenv init -)\"; fi' >> ~/.zprofile",
      "source ~/.zprofile",
      "rbenv install 3.0.4",
      "rbenv global 3.0.4",
      "sudo gem install bundler",
    ]
  }
  provisioner "shell" {
    inline = [
      "sudo safaridriver --enable",
      "networksetup -setdnsservers Ethernet 8.8.8.8 8.8.4.4 1.1.1.1",
    ]
  }
}
