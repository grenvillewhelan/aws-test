resource "aws_security_group" "capvwa" {
   count       = ceil(local.number_sg_rules / local.max_sg_entry)
   name        = "${var.my_manifest.region_alias}-${local.hyphenated_name}-sg${count.index}"
   vpc_id      = var.vpc_id
   description = "Control (${var.my_manifest.region_alias}) Security Group ${count.index}"

   tags = {
     Name = "${var.my_manifest.region_alias}-${local.hyphenated_name}-security-group${count.index}"
   }

   depends_on = [var.security_group_ids]
}

resource "aws_security_group_rule" "capvwa_ingress_cidr_blocks" {

   for_each = {for e,f in {for c,d in flatten([for a,b in [for name, entry in local.sg_rules["ingress"] : entry] : b]) : c=>d if d != null } : e=>f if lookup(f, "cidr_blocks", "") != ""}

   type                     = "ingress"
   from_port                = each.value.from_port
   to_port                  = each.value.to_port
   protocol                 = each.value.protocol
   description              = each.value.description
   cidr_blocks              = each.value.cidr_blocks
   security_group_id        = aws_security_group.capvwa[floor(sum(compact([for index, value in {for e,f in {for c,d in flatten([for a,b in [for name, entry in local.sg_rules["ingress"] : entry] : b]) : c=>d if d != null } : e=>length(try(f.cidr_blocks, ""))+length(try(f.sg_name, ""))} : index <= each.key ? value : ""])) / local.max_sg_entry)].id
}

resource "aws_security_group_rule" "capvwa_ingress_source_security_group_ids" {

   for_each = {for e,f in {for c,d in flatten([for a,b in [for name, entry in local.sg_rules["ingress"] : entry] : b]) : c=>d if d != null } : e=>f if lookup(f, "cidr_blocks", "") == ""}
 
   type                     = "ingress"
   from_port                = each.value.from_port
   to_port                  = each.value.to_port
   protocol                 = each.value.protocol
   description              = each.value.description
   source_security_group_id = var.security_group_ids[each.value.sg_name]
   security_group_id        = aws_security_group.capvwa[floor(sum(compact([for index, value in {for e,f in {for c,d in flatten([for a,b in [for name, entry in local.sg_rules["ingress"] : entry] : b]) : c=>d if d != null } : e=>length(try(f.cidr_blocks, ""))+length(try(f.sg_name, ""))} : index <= each.key ? value : ""])) / local.max_sg_entry)].id

}

resource "aws_security_group_rule" "capvwa_egress_cidr_blocks" {

   for_each = {for e,f in {for c,d in flatten([for a,b in [for name, entry in local.sg_rules["egress"] : entry] : b]) : c=>d if d != null } : e=>f if lookup(f, "cidr_blocks", "") != ""}

   type                     = "egress"
   from_port                = each.value.from_port
   to_port                  = each.value.to_port
   protocol                 = each.value.protocol
   description              = each.value.description
   cidr_blocks              = each.value.cidr_blocks
   security_group_id        = aws_security_group.capvwa[floor(sum(compact([for index, value in {for e,f in {for c,d in flatten([for a,b in [for name, entry in local.sg_rules["egress"] : entry] : b]) : c=>d if d != null } : e=>length(try(f.cidr_blocks, ""))+length(try(f.sg_name, ""))} : index <= each.key ? value : ""])) / local.max_sg_entry)].id
}

resource "aws_security_group_rule" "capvwa_egress_source_security_group_id" {
 
   for_each = {for e,f in {for c,d in flatten([for a,b in [for name, entry in local.sg_rules["egress"] : entry] : b]) : c=>d if d != null } : e=>f if lookup(f, "cidr_blocks", "") == ""}
    
   type                     = "egress"
   from_port                = each.value.from_port
   to_port                  = each.value.to_port
   protocol                 = each.value.protocol
   description              = each.value.description
   source_security_group_id = var.security_group_ids[each.value.sg_name]
   security_group_id        = aws_security_group.capvwa[floor(sum(compact([for index, value in {for e,f in {for c,d in flatten([for a,b in [for name, entry in local.sg_rules["egress"] : entry] : b]) : c=>d if d != null } : e=>length(try(f.cidr_blocks, ""))+length(try(f.sg_name, ""))} : index <= each.key ? value : ""])) / local.max_sg_entry)].id
}

