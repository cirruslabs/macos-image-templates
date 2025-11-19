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

locals {
  script_filename            = basename(var.script_path)
  script_remote_path         = "/Users/admin/${local.script_filename}"
  script_remote_path_quoted  = jsonencode(local.script_remote_path)
}

source "tart-cli" "tart" {
  vm_name      = var.vm_name
  ssh_password = "admin"
  ssh_username = "admin"
  ssh_timeout  = "120s"
}

build {
  sources = ["source.tart-cli.tart"]

  // Upload requested script into the admin user's home folder
  provisioner "file" {
    source      = var.script_path
    destination = local.script_remote_path
  }

  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "chmod +x ${local.script_remote_path_quoted}",
      local.script_remote_path_quoted,
      "rm ${local.script_remote_path_quoted}"
    ]
    pause_before = var.pause_before
  }
}
