locals {

   sg_rules = {
   
      "ingress" = {
   
         "${var.product_name}" = [
            {
               from_port                = 22
               to_port                  = 22
               protocol                 = "tcp"
               description              = "Cyberark external ingress SSH"
               cidr_blocks              = var.internet_control_access
            },
            {
               from_port                = 22
               to_port                  = 22
               protocol                 = "tcp"
               description              = "Cyberark external ingress SSH"
               cidr_blocks              = var.cidr_blocks[var.products["control"].subnet]
            },
            {
               from_port                = 1858
               to_port                  = 1858
               protocol                 = "tcp"
               description              = "Cyberark external ingress RDP"
               cidr_blocks              = var.cidr_blocks["all"]
            },
            {
               from_port                = 3389
               to_port                  = 3389
               protocol                 = "tcp"
               description              = "Cyberark external ingress RDP"
               cidr_blocks              = var.internet_control_access
            },
            {
               from_port                = 3389
               to_port                  = 3389
               protocol                 = "tcp"
               description              = "Cyberark external ingress RDP"
               cidr_blocks              = var.cidr_blocks["all"]
            }
         ]
      }
   
      "egress" = {
   
         "${var.product_name}" = [
            {
               from_port                = 0
               to_port                  = 0
               protocol                 = -1
               description              = "All ports out"
               cidr_blocks              = ["0.0.0.0/0"]
            }
         ]
      }
   }

   sg_rule_list = concat([for e,f in {for c,d in flatten([for a,b in [for name, entry in local.sg_rules["egress"] : entry] : b]) : c=>d if d != null } : lookup(f, "cidr_blocks", "") != "" ? length(f.cidr_blocks) : 1], [for e,f in {for c,d in flatten([for a,b in [for name, entry in local.sg_rules["ingress"] : entry] : b]) : c=>d if d != null } : lookup(f, "cidr_blocks", "") != "" ? length(f.cidr_blocks) : 1])
         
   number_sg_rules = sum(local.sg_rule_list)
            
   max_sg_entry = 60 - max(local.sg_rule_list...)

}
