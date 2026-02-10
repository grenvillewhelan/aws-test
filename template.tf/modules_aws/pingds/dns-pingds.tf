//resource "aws_route53_record" "pingds_lb" {
//
//   name    = "${var.dns_prefix}.${var.products[var.product_name].cluster}"
//   type    = "A"
//   zone_id = var.cloud_dns["aws"]["internal"].dns_zone_id 
//
//   alias {
//      evaluate_target_health = false
//      name                   = aws_lb.pingds.dns_name
//      zone_id                = aws_lb.pingds.zone_id
//   }
//
//   latency_routing_policy {
//      region = var.my_manifest.region_name
//   }
//
//   set_identifier = var.my_manifest.region_name
//
//   provider = aws.route53
//}

resource "aws_route53_record" "pingds_lb_region" {
   name    = "${var.dns_prefix}.${var.products[var.product_name].cluster}.${var.my_manifest.region_alias}"
   type    = "A"                                
   zone_id = var.cloud_dns["aws"]["internal"].dns_zone_id 

   alias {
      evaluate_target_health = false
      name                   = aws_lb.pingds.dns_name
      zone_id                = aws_lb.pingds.zone_id
   }
}

resource "aws_route53_record" "pingds-int" {
   count   = var.number_servers
//   name    = join (".", [aws_instance.pingds_server[count.index].id, var.my_manifest.region_alias])
   name    = "pingds-${count.index}"
   type    = "A"                                
   zone_id = var.cloud_dns["aws"]["internal"].dns_zone_id 
   records = [aws_instance.pingds_server[count.index].private_ip]
   ttl     = 60
}
