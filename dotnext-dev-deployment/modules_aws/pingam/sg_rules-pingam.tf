locals {

   sg_rules = {

      "ingress" = {
   
         "${var.product_name}" = [
            {
               from_port                = 22
               to_port                  = 22
               protocol                 = "tcp"
               description              = "PINGAM internal control ingress SSH"
               cidr_blocks              = var.cidr_blocks[var.products["control"].subnet]
            },
            {
               from_port                = 8081
               to_port                  = 8081
               protocol                 = "tcp"
               description              = "PINGAM ingress 8080"
               cidr_blocks              = var.cidr_blocks[var.products[var.product_name].subnet]
            },
            {
               from_port                = 8444
               to_port                  = 8444
               protocol                 = "tcp"
               description              = "PINGAM ingress 8444"
               cidr_blocks              = var.cidr_blocks[var.products[var.product_name].subnet]
            }
         ]

      }
   
      "egress" = {

         "${var.product_name}" = [
            {
               from_port                = 80
               to_port                  = 80
               protocol                 = "tcp"
               description              = "PINGAM egress HTTP"
               cidr_blocks              = ["0.0.0.0/0"]
            },
            {
               from_port                = 1389
               to_port                  = 1389
               protocol                 = "tcp"
               description              = "egress to PINGDS 1389"
               cidr_blocks              = var.cidr_blocks[var.products["pingds"].subnet]
            },
            {
               from_port                = 8081
               to_port                  = 8081
               protocol                 = "tcp"
               description              = "PINGAM egress 8081"
               cidr_blocks              = var.cidr_blocks[var.products[var.product_name].subnet]
            },
            {
               from_port                = 8444
               to_port                  = 8444
               protocol                 = "tcp"
               description              = "PINGAM egress 8444"
               cidr_blocks              = ["0.0.0.0/0"]
            }
         ]
      }
   }

   module_products = {for r in distinct([for a, b in var.products : b.module ]) : r =>distinct(compact([for x,y in var.products : y.module == r ? var.products_installed[x][var.my_manifest.region_alias] ? y.subnet : "" : ""]))}

   sg_rule_list = concat([for e,f in {for c,d in flatten([for a,b in [for name, entry in local.sg_rules["egress"] : entry] : b]) : c=>d if d != null } : lookup(f, "cidr_blocks", "") != "" ? length(f.cidr_blocks) : 1], [for e,f in {for c,d in flatten([for a,b in [for name, entry in local.sg_rules["ingress"] : entry] : b]) : c=>d if d != null } : lookup(f, "cidr_blocks", "") != "" ? length(f.cidr_blocks) : 1])
         
   number_sg_rules = sum(local.sg_rule_list)
   max_sg_entry = 60 - max(local.sg_rule_list...)
}
