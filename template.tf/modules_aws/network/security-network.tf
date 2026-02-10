resource "aws_security_group" "sg_members" {

   for_each    = toset(compact(flatten([for index,entry in keys(var.manifest[var.cloud_provider][var.region_number].products) : var.products_installed[entry][var.manifest[var.cloud_provider][var.region_number].region_alias] ? var.products[entry].module : ""]))) 

  name        = "${var.manifest[var.cloud_provider][var.region_number].region_alias}-${each.value}-sg-members"
  vpc_id      = aws_vpc.customer_network.id
  description = "${var.manifest[var.cloud_provider][var.region_number].region_alias} ${each.value} member security group"

  tags = {
    Name = "${var.manifest[var.cloud_provider][var.region_number].region_alias}-${each.value}-members-security-group"
  }
}
