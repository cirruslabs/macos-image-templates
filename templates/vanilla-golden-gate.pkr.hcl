packer {
  required_plugins {
    tart = {
      version = ">= 1.16.0"
      source  = "github.com/cirruslabs/tart"
    }
    ansible = {
      version = "~> 1"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

source "tart-cli" "tart" {
  from_ipsw    = "https://updates.cdn-apple.com/2026SummerSeed/fullrestores/140-55718/5809AFC6-1923-4590-AAFC-904A0283E659/UniversalMac_27.0_26A5388g_Restore.ipsw"
  vm_name      = "golden-gate-vanilla"
  cpu_count    = 4
  memory_gb    = 8
  disk_size_gb = 50
  ssh_password = "admin"
  ssh_username = "admin"
  ssh_timeout  = "180s"
  // Requires Tart 2.33.0+ and macOS 27+ on both the host and guest VM
  run_extra_args = [
    "--provisioning-opts=${join(",", [
      "fullName=Managed via Tart",
      "username=admin",
      "password=admin",
      "logsInAutomatically=true",
      "enablesRemoteLogin=true",
    ])}",
  ]
  boot_command = [
    # Wait for first-boot provisioning to finish automatic login
    "<wait120s>",
    # Enable Keyboard navigation
    # This is so that we can navigate the System Settings app using the keyboard
    "<wait10s><leftAltOn><spacebar><leftAltOff>Terminal<wait10s><enter>",
    "<wait10s><wait10s>defaults write NSGlobalDomain AppleKeyboardUIMode -int 3<enter>",
    # Disable Gatekeeper (1/2)
    "<wait10s>sudo spctl --global-disable<enter>",
    "<wait10s>admin<enter>",
    # Disable Gatekeeper (2/2)
    # On Tahoe opening System Settings through Spotlight is not very reliable, sometimes opens System information
    "<wait10s>open '/System/Applications/System Settings.app'<enter>",
    # Wait for System Settings to fully open before navigating with the keyboard
    "<wait120s>",
    "<wait10s><leftCtrlOn><f2><leftCtrlOff><right><right><right><down>Privacy & Security<enter>",
    "<wait10s><leftShiftOn><tab><tab><tab><tab><tab><tab><leftShiftOff>",
    "<wait10s><down><wait1s><down><wait1s><enter>",
    "<wait10s>admin<enter>",
    "<wait10s><leftShiftOn><tab><leftShiftOff><wait1s><spacebar>",
    # Quit System Settings
    "<wait10s><leftAltOn>q<leftAltOff>",
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
      // Enable passwordless sudo
      "echo admin | sudo -S sh -c \"mkdir -p /etc/sudoers.d/; echo 'admin ALL=(ALL) NOPASSWD: ALL' | EDITOR=tee visudo /etc/sudoers.d/admin-nopasswd\"",
      // Enable Screen Sharing for "tart run --vnc"
      "sudo launchctl enable system/com.apple.screensharing",
      // Use the same timezone as the previous Setup Assistant flow
      "sudo systemsetup -settimezone GMT 2>/dev/null",
      // Disable screensaver at login screen
      "sudo defaults write /Library/Preferences/com.apple.screensaver loginWindowIdleTime 0",
      // Disable screensaver for admin user
      "defaults -currentHost write com.apple.screensaver idleTime 0",
      // Prevent the VM from sleeping
      "sudo systemsetup -setsleep Off 2>/dev/null",
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
    ]
  }

  provisioner "shell" {
    inline = [
      # Ensure that Gatekeeper is disabled
      "spctl --status | grep -q 'assessments disabled'",
      # Ensure that FileVault remains disabled by default
      "sudo fdesetup status | grep -q 'FileVault is Off'",
    ]
  }
}
