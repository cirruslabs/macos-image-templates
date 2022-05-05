packer {
  required_plugins {
    tart = {
      version = ">= 0.3.1"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

source "tart-cli" "tart" {
  vm_base_name = "monterey-vanilla"
  vm_name      = "monterey-base"
  cpu_count    = 4
  memory_gb    = 8
  disk_size_gb = 30
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
      "yes '' | /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"",
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
      "brew install ruby ruby-build rbenv",
      "rbenv install $(rbenv install -l | grep -v - | tail -1)",
      "rbenv global $(rbenv install -l | grep -v - | tail -1)",
      "echo 'if which rbenv > /dev/null; then eval \"$(rbenv init -)\"; fi' >> ~/.zprofile",
      "source ~/.zprofile",
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
