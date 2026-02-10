locals {

   sg_rules = {
   
      "ingress" = {

         "ingress" = [
            {
               from_port                = 80
               to_port                  = 80
               protocol                 = "tcp"
               description              = "Web_Ingress external ingress HTTP"
               cidr_blocks              = ["0.0.0.0/0"]
            },
            {
               from_port                = 443
               to_port                  = 443
               protocol                 = "tcp"
               description              = "Web_Ingress external ingress HTTPS"
               cidr_blocks              = ["0.0.0.0/0"]
            }
         ]

         "pingfed_admin" = length(local.module_products["pingfed_admin"]) > 0 ? [
            {  
               from_port                = 9999
               to_port                  = 9999
               protocol                 = "tcp"
               description              = "Web_Ingress external egress to PINGDIR LDAPS"
               cidr_blocks              = ["0.0.0.0/0"]
            }
         ] : []

         "pingfed_runtime" = length(local.module_products["pingfed_runtime"]) > 0 ? [
            {
               from_port                = 9031
               to_port                  = 9031
               protocol                 = "tcp"
               description              = "Web_Ingress external ingress from PINGDIR LDAPS"
               cidr_blocks              = ["0.0.0.0/0"]
            },
            {
               from_port                = 7600
               to_port                  = 7600
               protocol                 = "tcp"
               description              = "Web_Ingress external ingress from PINGDIR LDAPS"
               cidr_blocks              = ["0.0.0.0/0"]
            },
            {
               from_port                = 7700
               to_port                  = 7700
               protocol                 = "tcp"
               description              = "Web_Ingress external inress from PINGDIR HTTPS"
               cidr_blocks              = ["0.0.0.0/0"]
            }
         ] : []

         "pingdir" = length(local.module_products["pingdir"]) > 0 ? [
            {
               from_port                = 1636
               to_port                  = 1636
               description              = "Web_Ingress external ingress LDAPS from PINGDIR"
               protocol                 = "tcp"
               cidr_blocks              = ["0.0.0.0/0"]
            },
            {
               from_port                = 8443
               to_port                  = 8443
               protocol                 = "tcp"
               description              = "Web_Ingress external ingress HTTPS from PINGDIR"
               cidr_blocks              =  ["0.0.0.0/0"]
            }
         ] : []

      }

      "egress" = {
   
         "ingress" = [
            {
               from_port                = 80
               to_port                  = 80
               protocol                 = "tcp"
               description              = "Web_Ingress external egress HTTP"
               cidr_blocks              = ["0.0.0.0/0"]
            },
            {
               from_port                = 443
               to_port                  = 443
               protocol                 = "tcp"
               description              = "Web_Ingress external egress HTTPS"
               cidr_blocks              = ["0.0.0.0/0"]
            }
         ]

         "pingdir" = length(local.module_products["pingdir"]) > 0 ? [
            {
               from_port                = 1636
               to_port                  = 1636
               description              = "Web_Ingress external egress LDAPS to PINGDIR"
               protocol                 = "tcp"
               cidr_blocks              = ["0.0.0.0/0"]
            },
            {
               from_port                = 8443
               to_port                  = 8443
               protocol                 = "tcp"
               description              = "Web_Ingress external egress HTTPS to PINGDIR"
               cidr_blocks              =  ["0.0.0.0/0"]
            }
         ] : []

         "pingfed_admin" = length(local.module_products["pingfed_admin"]) > 0 ? [
            {
               from_port                = 9999
               to_port                  = 9999
               protocol                 = "tcp"
               description              = "Web_Ingress external egress to PINGFED_ADMIN"
               cidr_blocks              = var.cidr_blocks[local.module_products["pingfed_admin"][0]]
            }
         ] : []

         "pingfed_runtime" = length(local.module_products["pingfed_runtime"]) > 0 ? [
            {
               from_port                = 9031
               to_port                  = 9031
               protocol                 = "tcp"
               description              = "Web_Ingress external egress to PINGFED_RUNTIME"
               cidr_blocks              = var.cidr_blocks[local.module_products["pingfed_runtime"][0]]
            },
            {
               from_port                = 7600
               to_port                  = 7600
               protocol                 = "tcp"
               description              = "Web_Ingress external egress to PINGDIR LDAPS"
               cidr_blocks              = ["0.0.0.0/0"]

            },
            {
               from_port                = 7700
               to_port                  = 7700
               protocol                 = "tcp"
               description              = "Web_Ingress external egress to PINGDIR HTTPS"
               cidr_blocks              = ["0.0.0.0/0"]
            }
         ] : []
      }
   }

   module_products = {for r in distinct([for a, b in var.products : b.module ]) : r =>distinct(compact([for x,y in var.products : y.module == r ? var.products_installed[x][var.my_manifest.region_alias] ? y.subnet : "" : ""]))}

   sg_rule_list = concat([for e,f in {for c,d in flatten([for a,b in [for name, entry in local.sg_rules["egress"] : entry] : b]) : c=>d if d != null } : lookup(f, "cidr_blocks", "") != "" ? length(f.cidr_blocks) : 1], [for e,f in {for c,d in flatten([for a,b in [for name, entry in local.sg_rules["ingress"] : entry] : b]) : c=>d if d != null } : lookup(f, "cidr_blocks", "") != "" ? length(f.cidr_blocks) : 1])
         
   number_sg_rules = sum(local.sg_rule_list)
            
   max_sg_entry = 60 - max(local.sg_rule_list...)

}

