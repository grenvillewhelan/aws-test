terraform {
   required_version = "~> 1.1"

   required_providers {

      aws = {
         source  = "hashicorp/aws"
         version = "~> 5.88.0"
      }

   }

   backend "s3" {
      bucket         = "dotnext-dev-tfstatefile"
      key            = "dotnext/state"
      region         = "eu-west-1"
      profile        = "dotnext_dev_remote_state"
      encrypt        = true
      dynamodb_table = "dotnext-dev-lockfile"
   }

}

provider "aws" {
   profile = join("_", [var.customer_name, terraform.workspace])
   alias   = "ireland"
   region  = "eu-west-1"

   default_tags {
      tags = {
         Customer    = var.customer_name
         Environment = terraform.workspace
      }
   }
}

provider "aws" {
  alias   = "route53"
  region  = "eu-west-1"
  profile = "dotnext_dev"

//  assume_role {
//    role_arn = "arn:aws:iam::762233743855:role/DNSManagerRole"
//  }
}

provider "aws" {
  alias   = "remote_state"
  region  = "eu-west-1"
  profile = var.remote_state
}

