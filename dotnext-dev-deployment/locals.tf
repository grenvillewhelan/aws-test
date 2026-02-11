
locals {

   san_list = distinct([for c, d in compact(flatten([for a,b in var.manifest["aws"] : [for index,entry in var.products : var.manifest["aws"][a].products[index][terraform.workspace] > 0 ? split(",", try(entry.parameters["dns_prefix"], "")) : []]])) : trimspace(join(".", [d, terraform.workspace, var.customer_name, var.dns_suffix[var.cloud_provider]]))])

   cloud_providers       = ["aws"]
   tenant_id             = "32e7422c-0a0d-48fd-b631-e2f22d217eff"
   client_id             = "no-azure-not-applicable"
   client_secret         = "no-azure-not-applicable"

   cloud_peerings = {
      aws = {
         "azure" = []
      }
   }

   subnet_cidr_blocks = {
      "internet"   = concat(module.network_ireland.vpc_subnet_cidr_blocks["internet"])
      "admin"      = concat(module.network_ireland.vpc_subnet_cidr_blocks["admin"])
      "application" = concat(module.network_ireland.vpc_subnet_cidr_blocks["application"])
      "management" = concat(module.network_ireland.vpc_subnet_cidr_blocks["management"])
      "data"       = concat(module.network_ireland.vpc_subnet_cidr_blocks["data"])
      "wan"        = concat(module.network_ireland.vpc_subnet_cidr_blocks["wan"])
      "all"        = concat([for index,val in var.manifest["aws"] : var.manifest["aws"][index].network_range[terraform.workspace]])
   }

   products_installed = {
      "aws" = {
         "cacpm"      = {
            "ireland"    = true
         }
         "capsm"      = {
            "ireland"    = true
         }
         "capsml"     = {
            "ireland"    = true
         }
         "capsmp"     = {
            "ireland"    = true
         }
         "capvwa"     = {
            "ireland"    = true
         }
         "cavault"    = {
            "ireland"    = true
         }
         "control"    = {
            "ireland"    = true
         }
         "network"    = {
            "ireland"    = true
         }
         "pingam"     = {
            "ireland"    = true
         }
         "pingds"     = {
            "ireland"    = true
         }
         "pingidm"    = {
            "ireland"    = true
         }
         "web_ingress" = {
            "ireland"    = false
         }
      }
   }

   vpcs = {
      "ireland"    = module.network_ireland.vpc_id
   }

   cloud_dns = {

      "aws" = {
         "internal" = {
            dns_zone_id   = module.network_ireland.internal_dns_zone_id
            dns_zone_name = module.network_ireland.internal_dns_zone_name
         }
         "external" = {
            dns_zone_id   = module.network_ireland.external_dns_zone_id
            dns_zone_name = module.network_ireland.external_dns_zone_name
         }
      }
   }

   security_group_ids = {

      "ireland"    = {
         cacpm                 = module.network_ireland.security_group_ids["cacpm"]
         capsm                 = module.network_ireland.security_group_ids["capsm"]
         capsml                = module.network_ireland.security_group_ids["capsml"]
         capsmp                = module.network_ireland.security_group_ids["capsmp"]
         capvwa                = module.network_ireland.security_group_ids["capvwa"]
         cavault               = module.network_ireland.security_group_ids["cavault"]
         control               = module.network_ireland.security_group_ids["control"]
         network               = module.network_ireland.security_group_ids["network"]
         pingam                = module.network_ireland.security_group_ids["pingam"]
         pingds                = module.network_ireland.security_group_ids["pingds"]
         pingidm               = module.network_ireland.security_group_ids["pingidm"]
         web_ingress           = ""
      }
   }

   peer_accepts = {
      "ireland"                = {}
   }

   peer_connects = {
      "ireland"                = {}
   }

   aws_vpn_connections = {}
   azure_vpn_connections = {}
   subnet_ids = {
      "ireland"                = module.network_ireland.vpc_subnet_ids
   }
}
