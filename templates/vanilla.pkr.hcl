packer {
  required_plugins {
    tart = {
      version = ">= 0.5.0"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

variable "macos_version" {
  type =  string
  default = "ventura"
}

source "tart-cli" "tart" {
  from_ipsw    = "latest"
  vm_name      = "${var.macos_version}-vanilla"
  cpu_count    = 4
  memory_gb    = 8
  disk_size_gb = 50
  ssh_password = "admin"
  ssh_username = "admin"
  ssh_timeout  = "120s"
  boot_command = [
    # hello, hola, bonjour, etc.
    "<wait60s><spacebar>",
    # Language
    "<wait30s><enter>",
    # Select Your Country and Region
    "<wait10s>united states<leftShiftOn><tab><leftShiftOff><spacebar>",
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
    "<wait10s><tab><spacebar><leftShiftOn><tab><leftShiftOff><spacebar>",
    # Screen Time
    "<wait10s><tab><spacebar>",
    # Siri
    "<wait10s><tab><spacebar><leftShiftOn><tab><leftShiftOff><spacebar>",
    # Choose Your Look
    "<wait10s><leftShiftOn><tab><leftShiftOff><spacebar>",
    # Enable Voice Over
    "<wait10s><leftAltOn><f5><leftAltOff><wait5s>v",
    # Now that the installation is done, open "System Preferences"
    "<wait10s><leftAltOn><spacebar><leftAltOff>System Preferences<enter>",
    # Navigate to "Sharing"
    "<wait10s>sharing<enter>",
    # Enable Remote Login
    "<wait10s><tab><tab><tab><down><down><down><down><spacebar><tab><tab><spacebar>",
    # Disable Voice Over
    "<wait10s><leftAltOn><f5><leftAltOff>",
  ]
}

build {
  sources = ["source.tart-cli.tart"]
}
