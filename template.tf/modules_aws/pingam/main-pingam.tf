terraform {
   required_providers {
      aws = {
         source  = "hashicorp/aws"
         version = "~> !!TF_AWS_VERSION!!"
         configuration_aliases = [ aws.route53, aws ]
      }
   }
}
