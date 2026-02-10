resource "aws_route53_record" "apps" {

   for_each = {for x in compact([for x,y in var.products : var.my_manifest.products[x][terraform.workspace] > 0 && length(lookup(var.products[x].parameters, "healthcheck_path", "")) > 0 ? x : ""]) : x => x}

   name    = join(".", [lookup(var.products[each.key].parameters, "dns_prefix", ""), terraform.workspace, var.customer_name, var.dns_suffix["aws"]])

   type    = "A"
   zone_id = var.cloud_dns["aws"]["external"].dns_zone_id

   alias {
      evaluate_target_health = false
      name                   = aws_lb.ingress_lb.dns_name
      zone_id                = aws_lb.ingress_lb.zone_id
   }

   latency_routing_policy {
      region = var.my_manifest.region_name
   }
  
   set_identifier = var.my_manifest.region_name
   health_check_id = aws_route53_health_check.apps[each.key].id
   provider = aws.route53
}

resource "aws_route53_health_check" "apps" {
   for_each = {for x in compact([for x,y in var.products : var.my_manifest.products[x][terraform.workspace] > 0 && length(lookup(var.products[x].parameters, "healthcheck_path", "")) > 0 && lookup(var.products[x].parameters, "dns_prefix", "") != "" ? x : ""]) : x => x}

  fqdn              = join(".", [lookup(var.products[each.key].parameters, "dns_prefix", ""), terraform.workspace, var.customer_name, var.dns_suffix["aws"]])
  port              = lookup(var.products[each.key].parameters, "backend_port", 443)
  type              = "HTTPS"
  resource_path     = lookup(var.products[each.key].parameters, "healthcheck_path", "")
  failure_threshold = lookup(var.products[each.key].parameters, "unhealthy_threshold", 3)
  request_interval  = lookup(var.products[each.key].parameters, "healthcheck_interval", 5)

  tags = {
    Name = "${var.my_manifest.region_alias}-${lookup(var.products[each.key].parameters, "dns_prefix", "")}-health-check"
  }
}

