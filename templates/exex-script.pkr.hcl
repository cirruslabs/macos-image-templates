packer {
  required_plugins {
    tart = {
      version = ">= 1.12.0"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

variable "vm_name" {
  type = string
}

variable "script_path" {
  type        = string
  description = "Path to a local script that should be uploaded and executed inside the VM."
}

variable "pause_before" {
  type        = string
  default     = "60s"
  description = "How long Packer should wait before running the uploaded script."
}

source "tart-cli" "tart" {
  vm_name      = "${var.vm_name}"
  ssh_password = "admin"
  ssh_username = "admin"
  ssh_timeout  = "120s"
}

build {
  sources = ["source.tart-cli.tart"]

  provisioner "shell" {
    script = var.script_path
    pause_before = var.pause_before
  }
}
