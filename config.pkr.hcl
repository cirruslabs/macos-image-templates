packer {
  required_plugins {
    parallels = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/parallels"
    }
    tart = {
      version = ">= 0.1.0"
      source  = "github.com/cirruslabs/tart"
    }
    veertu-anka = {
      version = ">= v2.3.0"
      source = "github.com/veertuinc/veertu-anka"
    }
  }
}
