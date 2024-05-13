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

source "tart-cli" "tart" {
  vm_base_name = "ghcr.io/cirruslabs/macos-${var.macos_version}-vanilla:latest"
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

  provisioner "file" {
    source      = "data/limit.maxfiles.plist"
    destination = "~/limit.maxfiles.plist"
  }

  provisioner "shell" {
    inline = [
      "echo 'Configuring maxfiles...'",
      "sudo mv ~/limit.maxfiles.plist /Library/LaunchDaemons/limit.maxfiles.plist",
      "sudo chown root:wheel /Library/LaunchDaemons/limit.maxfiles.plist",
      "sudo chmod 0644 /Library/LaunchDaemons/limit.maxfiles.plist",
      "echo 'Disabling spotlight...'",
      "sudo mdutil -a -i off",
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
      "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"",
      "echo \"export LANG=en_US.UTF-8\" >> ~/.zprofile",
      "echo 'eval \"$(/opt/homebrew/bin/brew shellenv)\"' >> ~/.zprofile",
      "echo \"export HOMEBREW_NO_AUTO_UPDATE=1\" >> ~/.zprofile",
      "echo \"export HOMEBREW_NO_INSTALL_CLEANUP=1\" >> ~/.zprofile",
      "source ~/.zprofile",
      "brew --version",
      "brew update",
      "brew install curl wget unzip zip ca-certificates cmake gcc git-lfs jq gh gitlab-runner",
      "brew install --cask git-credential-manager",
      "git lfs install",
      "sudo softwareupdate --install-rosetta --agree-to-license"
    ]
  }

  // Install the GitHub Actions runner
  provisioner "shell" {
    script = "scripts/install-actions-runner.sh"
  }

  // Create a /Users/runner → /Users/admin symlink to support certain GitHub Actions
  // like ruby/setup-ruby that hard-code the "/Users/runner/hostedtoolcache" path[1]
  //
  // [1]: https://github.com/ruby/setup-ruby/blob/6bd3d993c602f6b675728ebaecb2b569ff86e99b/common.js#L268
  provisioner "shell" {
    inline = [
      "sudo ln -s /Users/admin /Users/runner"
    ]
  }

  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "brew install libyaml", # https://github.com/rbenv/ruby-build/discussions/2118
      "brew install rbenv",
      "echo 'if which rbenv > /dev/null; then eval \"$(rbenv init -)\"; fi' >> ~/.zprofile",
      "source ~/.zprofile",
      "rbenv install 2.7.8", // latest 2.x.x before EOL
      "rbenv install -l | grep -v - | tail -2 | xargs -L1 rbenv install",
      "rbenv global $(rbenv install -l | grep -v - | tail -1)",
      "gem install bundler",
    ]
  }
  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "brew install node@20",
      "echo 'export PATH=\"/opt/homebrew/opt/node@20/bin:$PATH\"' >> ~/.zprofile",
      "source ~/.zprofile",
      "node --version",
      "npm install --global yarn",
      "yarn --version",
    ]
  }
  provisioner "shell" {
    inline = [
      "sudo safaridriver --enable",
    ]
  }
  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "brew install awscli"
    ]
  }

  # Enable UI automation, see https://github.com/cirruslabs/macos-image-templates/issues/136
  provisioner "shell" {
    script = "scripts/automationmodetool.expect"
  }

  // some other health checks
  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "test -d /Users/runner"
    ]
  }
}
