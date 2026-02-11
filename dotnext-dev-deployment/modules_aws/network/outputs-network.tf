output "vpc_id" {
   value = aws_vpc.customer_network.id
}

output "route_table_id" {
   value = aws_vpc.customer_network.main_route_table_id
}

output "vpc_subnet_cidr_blocks" {
   value = {for index,subnet in [for index, name in var.subnets : var.subnets[index].subnet_name] : subnet => flatten(compact([for index, name in aws_subnet.vpc_subnets[*].tags_all["Subnet"] : name == subnet ? aws_subnet.vpc_subnets[index].cidr_block : ""]))}
}

output "vpc_subnet_ids" {

   value = {for index,subnet in [for index, name in var.subnets : var.subnets[index].subnet_name] : subnet => flatten(compact([for index, name in aws_subnet.vpc_subnets[*].tags_all["Subnet"] : name == subnet ? aws_subnet.vpc_subnets[index].id : ""]))}

}

output "external_dns_zone_id" {
   value = aws_route53_zone.accessidentifiedcloud.zone_id
}

output "external_dns_zone_name" {
   value = aws_route53_zone.accessidentifiedcloud.name
}

output "internal_dns_zone_id" {
  value = var.region_number == 0 ? aws_route53_zone.internal_dns_zone[0].id : ""
}

output "internal_dns_zone_name" {
  value = var.region_number == 0 ? aws_route53_zone.internal_dns_zone[0].name : ""
}

output "security_group_ids" {
  value = {
    for product, security_group in aws_security_group.sg_members : product => security_group.id
  }
}

output "peer_connect_id" {

  value = var.region_number + 1 < length (var.manifest[var.cloud_provider]) ? {
    for name in aws_vpc_peering_connection.peering_connection[*]:
      name.tags.Region => name.id
  } : {} 

}

output "peer_accept_id" {

   value = var.region_number > 0 ? {
     for name in aws_vpc_peering_connection_accepter.peering_accepter[*]:
      name.tags.Region => name.id
   } : {}
}
