packer {
  required_plugins {
    tart = {
      version = ">= 1.12.0"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

variable "vm_base_name" {
  type = string
}

variable "vm_name" {
  type = string
}

variable "resolve_file" {
  type = string
}

source "tart-cli" "tart" {
  vm_base_name = "${var.vm_base_name}"
  vm_name      = "${var.vm_name}"
  cpu_count    = 4
  memory_gb    = 8
  ssh_password = "admin"
  ssh_username = "admin"
  ssh_timeout  = "120s"
}

build {
  sources = ["source.tart-cli.tart"]

  provisioner "shell" {
    inline = [
      "sw_vers --productVersion > /tmp/sw-vers-product-version.txt",
    ]
  }

  provisioner "file" {
    source = "/tmp/sw-vers-product-version.txt"
    destination = "${var.resolve_file}"
    direction = "download"
  }
}
