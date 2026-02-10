locals {

   sg_rules = {
   
      "ingress" = {
   
         "${var.product_name}" = [
            {
               from_port                = 22
               to_port                  = 22
               protocol                 = "tcp"
               description              = "Control external ingress SSH"
               cidr_blocks              = var.internet_control_access
            },
            {
               from_port                = 22
               to_port                  = 22
               protocol                 = "tcp"
               description              = "Control internal ingress SSH"
               sg_name                  = "${var.product_name}"
            },
            {
               from_port                = 22
               to_port                  = 22
               protocol                 = "tcp"
               description              = "Control internal multiregion ingress SSH"
               cidr_blocks              = var.cidr_blocks[var.products[var.product_name].subnet]
            },
            {
               from_port                = -1
               to_port                  = -1
               protocol                 = "icmp"
               description              = "Control internal multiregion ingress ICMP"
               cidr_blocks              = ["0.0.0.0/0"]
            }
         ]
      }
   
      "egress" = {
   
         "${var.product_name}" = [
            {
               from_port                = 22
               to_port                  = 22
               protocol                 = "tcp"
               description              = "Control external egress SSH"
               cidr_blocks              = var.cidr_blocks["all"]
            },
            {
               from_port                = 80
               to_port                  = 80
               protocol                 = "tcp"
               description              = "Control egress HTTP"
               cidr_blocks              = ["0.0.0.0/0"]
            },
            {
               from_port                = 443
               to_port                  = 443
               protocol                 = "tcp"
               description              = "Control external egress HTTPS"
               cidr_blocks              = ["0.0.0.0/0"]
            },
            {
               from_port                = -1
               to_port                  = -1
               protocol                 = "icmp"
               description              = "Control internal multiregion ingress ICMP"
               cidr_blocks              = ["0.0.0.0/0"]
            },
            {
               from_port                = 3389
               to_port                  = 3389
               protocol                 = "tcp"
               description              = "Control external egress HTTPS"
               cidr_blocks              = var.cidr_blocks["all"]
            }
         ]
      }
   }

   sg_rule_list = concat([for e,f in {for c,d in flatten([for a,b in [for name, entry in local.sg_rules["egress"] : entry] : b]) : c=>d if d != null } : lookup(f, "cidr_blocks", "") != "" ? length(f.cidr_blocks) : 1], [for e,f in {for c,d in flatten([for a,b in [for name, entry in local.sg_rules["ingress"] : entry] : b]) : c=>d if d != null } : lookup(f, "cidr_blocks", "") != "" ? length(f.cidr_blocks) : 1])
         
   number_sg_rules = sum(local.sg_rule_list)
            
   max_sg_entry = 60 - max(local.sg_rule_list...)

}
