packer {
  required_plugins {
    tart = {
      version = ">= 1.12.0"
      source  = "github.com/cirruslabs/tart"
    }
    ansible = {
      version = "~> 1"
      source = "github.com/hashicorp/ansible"
    }
  }
}

source "tart-cli" "tart" {
  # You can find macOS IPSW URLs on various websites like https://ipsw.me/
  # and https://www.theiphonewiki.com/wiki/Beta_Firmware/Mac/13.x
  from_ipsw    = "https://updates.cdn-apple.com/2023FallFCS/fullrestores/042-55833/C0830847-A2F8-458F-B680-967991820931/UniversalMac_13.6_22G120_Restore.ipsw"
  vm_name      = "ventura-vanilla"
  cpu_count    = 4
  memory_gb    = 8
  disk_size_gb = 40
  ssh_password = "admin"
  ssh_username = "admin"
  ssh_timeout  = "120s"
  boot_command = [
    # hello, hola, bonjour, etc.
    "<wait60s><spacebar>",
    # Language: most of the times we have a list of "English"[1], "English (UK)", etc. with
    # "English" language already selected. If we type "english", it'll cause us to switch
    # to the "English (UK)", which is not what we want. To solve this, we switch to some other
    # language first, e.g. "Italiano" and then switch back to "English". We'll then jump to the
    # first entry in a list of "english"-prefixed items, which will be "English".
    #
    # [1]: should be named "English (US)", but oh well 🤷
    "<wait30s>italiano<esc>english<enter>",
    # Select Your Country and Region
    "<wait30s>united states<leftShiftOn><tab><leftShiftOff><spacebar>",
    # Written and Spoken Languages
    "<wait10s><leftShiftOn><tab><leftShiftOff><spacebar>",
    # Accessibility
    "<wait10s><leftShiftOn><tab><leftShiftOff><spacebar>",
    # Data & Privacy
    "<wait10s><leftShiftOn><tab><leftShiftOff><spacebar>",
    # Migration Assistant
    "<wait10s><tab><tab><tab><spacebar>",
    # Sign In with Your Apple ID
    "<wait10s><leftShiftOn><tab><leftShiftOff><leftShiftOn><tab><leftShiftOff><spacebar>",
    # Are you sure you want to skip signing in with an Apple ID?
    "<wait10s><tab><spacebar>",
    # Terms and Conditions
    "<wait10s><leftShiftOn><tab><leftShiftOff><spacebar>",
    # I have read and agree to the macOS Software License Agreement
    "<wait10s><tab><spacebar>",
    # Create a Computer Account
    "<wait10s>admin<tab><tab>admin<tab>admin<tab><tab><tab><spacebar>",
    # Enable Location Services
    "<wait10s><leftShiftOn><tab><leftShiftOff><spacebar>",
    # Are you sure you don't want to use Location Services?
    "<wait10s><tab><spacebar>",
    # Select Your Time Zone
    "<wait10s><tab>UTC<enter><leftShiftOn><tab><leftShiftOff><spacebar>",
    # Analytics
    "<wait10s><leftShiftOn><tab><leftShiftOff><spacebar>",
    # Screen Time
    "<wait10s><tab><spacebar>",
    # Siri
    "<wait10s><tab><spacebar><leftShiftOn><tab><leftShiftOff><spacebar>",
    # Choose Your Look
    "<wait10s><leftShiftOn><tab><leftShiftOff><spacebar>",
    # Enable Voice Over
    "<wait10s><leftAltOn><f5><leftAltOff><wait5s>v",
    # Now that the installation is done, open "System Settings"
    "<wait10s><leftAltOn><spacebar><leftAltOff>System Settings<enter>",
    # Navigate to "Sharing"
    "<wait10s><leftAltOn>f<leftAltOff>sharing<enter>",
    # Navigate to "Screen Sharing" and enable it
    "<wait10s><tab><down><spacebar>",
    # Navigate to "Remote Login" and enable it
    "<wait10s><tab><tab><tab><tab><tab><tab><spacebar>",
    # Open "Remote Login" details
    "<wait10s><tab><spacebar>",
    # Enable "Full Disk Access"
    "<wait10s><tab><spacebar>",
    # Click "Done"
    "<wait10s><leftShiftOn><tab><leftShiftOff><leftShiftOn><tab><leftShiftOff><spacebar>",
    # Disable Voice Over
    "<leftAltOn><f5><leftAltOff>",
  ]

  // A (hopefully) temporary workaround for Virtualization.Framework's
  // installation process not fully finishing in a timely manner
  create_grace_time = "30s"

  // Keep the recovery partition, otherwise it's not possible to "softwareupdate"
  recovery_partition = "keep"
}

build {
  sources = ["source.tart-cli.tart"]

  provisioner "shell" {
    inline = [
      # Install command-line tools
      "touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress",
      "softwareupdate --list | sed -n 's/.*Label: \\(Command Line Tools for Xcode-.*\\)/\\1/p' | tr '\\n' '\\0' | xargs -0 softwareupdate --install",
      "rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress",
    ]
  }

  provisioner "ansible" {
    playbook_file = "../ansible/playbook-system-updater.yml"

    # scp command is only available after we install the openssh-client
    use_sftp = true
  }

  provisioner "shell" {
    inline = [
      // Enable passwordless sudo
      "echo admin | sudo -S sh -c \"mkdir -p /etc/sudoers.d/; echo 'admin ALL=(ALL) NOPASSWD: ALL' | EDITOR=tee visudo /etc/sudoers.d/admin-nopasswd\"",
      // Enable auto-login
      //
      // See https://github.com/xfreebird/kcpassword for details.
      "echo '00000000: 1ced 3f4a bcbc ba2c caca 4e82' | sudo xxd -r - /etc/kcpassword",
      "sudo defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser admin",
      // Disable screensaver at login screen
      "sudo defaults write /Library/Preferences/com.apple.screensaver loginWindowIdleTime 0",
      // Disable screensaver for admin user
      "defaults -currentHost write com.apple.screensaver idleTime 0",
      // Prevent the VM from sleeping
      "sudo systemsetup -setdisplaysleep Off 2>/dev/null",
      "sudo systemsetup -setsleep Off 2>/dev/null",
      "sudo systemsetup -setcomputersleep Off 2>/dev/null",
      // Launch Safari to populate the defaults
      "/Applications/Safari.app/Contents/MacOS/Safari &",
      "SAFARI_PID=$!",
      "disown",
      "sleep 30",
      "kill -9 $SAFARI_PID",
      // Enable Safari's remote automation
      "sudo safaridriver --enable",
      // Disable screen lock
      //
      // Note that this only works if the user is logged-in,
      // i.e. not on login screen.
      "sysadminctl -screenLock off -password admin",
      "defaults -currentHost write com.apple.screensaver idleTime 0"
    ]
  }
}
