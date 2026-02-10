resource "aws_vpc_peering_connection" "peering_connection" {
  count          = var.region_number + 1 < length (var.manifest[var.cloud_provider]) ? length(var.manifest[var.cloud_provider]) - var.region_number -1 : 0
  peer_owner_id  = var.account_owner
  peer_vpc_id    = var.vpcs[var.manifest[var.cloud_provider][var.region_number + 1 +  count.index].region_alias]
  peer_region    = var.manifest[var.cloud_provider][var.region_number + 1 +  count.index].region_name
  vpc_id         = var.vpcs[var.manifest[var.cloud_provider][var.region_number].region_alias]

  tags = {
    Region = var.manifest[var.cloud_provider][var.region_number + 1 + count.index].region_name
    Name = "${var.manifest[var.cloud_provider][var.region_number].region_alias} Requester to ${var.manifest[var.cloud_provider][var.region_number + 1 + count.index].region_alias}"
  }

  lifecycle {
    ignore_changes = [ accepter ]
  }
}

resource "aws_vpc_peering_connection_accepter" "peering_accepter" {
  count                      = var.region_number > 0 ? var.region_number : 0
  vpc_peering_connection_id  = var.peer_connects[var.manifest[var.cloud_provider][count.index].region_alias][var.manifest[var.cloud_provider][var.region_number].region_name]
  auto_accept                = true

  tags = {
    Region = var.manifest[var.cloud_provider][count.index].region_name
    Name = "${var.manifest[var.cloud_provider][var.region_number].region_alias} Accepter to ${var.manifest[var.cloud_provider][count.index].region_alias}"
  }
}
