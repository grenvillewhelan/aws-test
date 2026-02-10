packer {

  required_plugins {
    amazon = {
      version = ">= 1.2.1"
      source  = "github.com/hashicorp/amazon"
    }

    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 2"
    }
  }
}

