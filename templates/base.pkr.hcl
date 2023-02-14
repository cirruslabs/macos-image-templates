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
}

variable "gha_version" {
  type =  string
}

source "tart-cli" "tart" {
  vm_base_name = "ghcr.io/cirruslabs/macos-${var.macos_version}-vanilla:13.2"
  vm_name      = "${var.macos_version}-base"
  cpu_count    = 4
  memory_gb    = 8
  disk_size_gb = 50
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

  # setup DNS
  provisioner "shell" {
    inline = [
      "networksetup -setdnsservers Ethernet 8.8.8.8 8.8.4.4 1.1.1.1",
    ]
  }

  # Create a symlink for bash compatibility
  provisioner "shell" {
    inline = [
      "touch ~/.zprofile",
      "ln -s ~/.zprofile ~/.profile",
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
      "brew install wget cmake gcc git-lfs jq gh",
      "git lfs install",
    ]
  }
  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "brew install rbenv",
      "echo 'if which rbenv > /dev/null; then eval \"$(rbenv init -)\"; fi' >> ~/.zprofile",
      "source ~/.zprofile",
      "rbenv install 3.0.5",
      "rbenv global 3.0.5",
      "gem install bundler",
    ]
  }
  provisioner "shell" {
    inline = [
      "sudo safaridriver --enable",
    ]
  }
}
