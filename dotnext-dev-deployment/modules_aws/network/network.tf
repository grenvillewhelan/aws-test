resource "aws_vpc" "customer_network" {
  cidr_block           = var.manifest[var.cloud_provider][var.region_number].network_range[terraform.workspace]
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = join("_", [ var.manifest[var.cloud_provider][var.region_number].region_alias, "customer_network" ] )
  }
}

resource "aws_subnet" "vpc_subnets" {
   count             = length(var.manifest[var.cloud_provider][var.region_number].azs) * length(var.subnets)

   cidr_block        = cidrsubnet(aws_vpc.customer_network.cidr_block, var.subnets[count.index % length(var.subnets)].newbits, var.subnets[count.index % length(var.subnets)].netnum + floor(count.index / length(var.subnets)))

   availability_zone = join("", [var.manifest[var.cloud_provider][var.region_number].region_name, var.manifest[var.cloud_provider][var.region_number].azs[floor(count.index / length(var.subnets))]])

   vpc_id            = aws_vpc.customer_network.id
   enable_resource_name_dns_a_record_on_launch = true

   tags = {
     Name = join("_", [ var.manifest[var.cloud_provider][var.region_number].region_alias, var.subnets[count.index % length(var.subnets)].subnet_name, var.manifest[var.cloud_provider][var.region_number].azs[floor(count.index / length(var.subnets))]])
     Subnet = var.subnets[count.index % length(var.subnets)].subnet_name
     TableEntry = count.index
   }
}

resource "aws_route_table" "vpc_route_table" {
   count  = length(var.subnets) * length(var.manifest[var.cloud_provider][var.region_number].azs)
   vpc_id = aws_vpc.customer_network.id

   route {
     cidr_block = "0.0.0.0/0"
     gateway_id = var.subnets[count.index % length(var.subnets)].subnet_name == var.products["network"].subnet || var.subnets[count.index % length(var.subnets)].subnet_name == var.products["control"].subnet ? aws_internet_gateway.internet_gateway.id : aws_nat_gateway.customer_nat_gw[count.index % length(var.manifest[var.cloud_provider][var.region_number].azs)].id
   }

   dynamic "route" {

      for_each = {for region in compact([for region,entry in var.regions : region != var.region_number ? region : ""]) : region => region}

      content {
         cidr_block = lookup(var.manifest[var.cloud_provider][route.key].network_range, terraform.workspace)
         vpc_peering_connection_id = try(var.peer_connects[var.manifest[var.cloud_provider][var.region_number].region_alias][var.manifest[var.cloud_provider][route.value].region_name], var.peer_accepts[var.manifest[var.cloud_provider][var.region_number].region_alias][var.manifest[var.cloud_provider][route.value].region_name])
      }
   }

   dynamic "route" {

      for_each = {for entry,x in flatten([for a,b in var.other_cloud_regions : compact([for c,d in var.manifest[b] : d.enable_vpn && var.subnets[count.index % length(var.subnets)].subnet_name != "wank" ? d.network_range[terraform.workspace] : ""])]) : flatten([for a,b in var.other_cloud_regions : [for c,d in var.manifest[b] : d.region_alias]])[entry] => x}

      content {
         cidr_block = route.value
         gateway_id = aws_vpn_gateway.aws2azure[0].id
      }
   }

   tags = {
     Name = join("_", [ var.manifest[var.cloud_provider][var.region_number].region_alias, var.subnets[count.index % length(var.subnets)].subnet_name, var.manifest[var.cloud_provider][var.region_number].azs[floor(count.index / length(var.subnets))]])
   }

   lifecycle {
     ignore_changes = [ id, route ]
   }

   depends_on = [  aws_vpc_peering_connection.peering_connection,
                   aws_vpc_peering_connection_accepter.peering_accepter ]

}

resource "aws_route_table_association" "vpc_route_association" {
   count          = length(var.manifest[var.cloud_provider][var.region_number].azs) * length(var.subnets)
   route_table_id = aws_route_table.vpc_route_table[count.index].id
   subnet_id      = aws_subnet.vpc_subnets[count.index].id
}

resource "aws_eip" "nat_gw_ip" {
  count = length(var.manifest[var.cloud_provider][var.region_number].azs)
  domain = "vpc"
}     
      
resource "aws_eip" "secondary_nat_gw_ip" {
  count = (length(var.manifest[var.cloud_provider][var.region_number].azs) * var.nat_number_secondary_ips)
  domain = "vpc"
} 

resource "aws_nat_gateway" "customer_nat_gw" {
  count         = length(var.manifest[var.cloud_provider][var.region_number].azs)
  allocation_id = aws_eip.nat_gw_ip[count.index].id
  subnet_id     = flatten(compact([for index, name in aws_subnet.vpc_subnets[*].tags_all["Subnet"] : name == "internet" ? aws_subnet.vpc_subnets[aws_subnet.vpc_subnets[index].tags_all["TableEntry"]].id : ""]))[count.index]

//  secondary_allocation_ids = slice (aws_eip.secondary_nat_gw_ip[*].id, (count.index * var.nat_number_secondary_ips), ((count.index +1) * var.nat_number_secondary_ips))
    
  tags = {
    Name = join("-", [ var.manifest[var.cloud_provider][var.region_number].region_alias, var.manifest[var.cloud_provider][var.region_number].azs[count.index], "nat-gw" ] )
  }

  depends_on    = [aws_internet_gateway.internet_gateway ]
  
  lifecycle {
     ignore_changes = [  id, tags ]
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.customer_network.id

  tags = {
    Name = join("_", [ var.manifest[var.cloud_provider][var.region_number].region_alias, "internet_gateway" ] )
  }
}
