resource "aws_route53_zone" "internal_dns_zone" {
  count         = var.region_number == var.first_region_running ? 1 : 0
  name          = join(".", ["int", terraform.workspace, var.customer_name])
  force_destroy = true

  vpc {
    vpc_id = aws_vpc.customer_network.id
  }

  lifecycle {
    ignore_changes = [vpc]
  }
}

resource "aws_route53_zone_association" "multiregion_zone_association" {
  count   = var.region_number > 0 ? 1 : 0
  zone_id = var.cloud_dns["aws"]["internal"].dns_zone_id
  vpc_id  = var.vpcs[var.manifest[var.cloud_provider][var.region_number].region_alias]
}
