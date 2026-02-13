resource "aws_route53_record" "pingds_lb_internal_ldaps" {
   name    = "${var.dns_prefix}"
   type    = "A"                                
   zone_id = var.cloud_dns["aws"]["internal"].dns_zone_id 

   alias {
      evaluate_target_health = false
      name                   = aws_lb.pingds.dns_name
      zone_id                = aws_lb.pingds.zone_id
   }
}

resource "aws_route53_record" "pingds_lb_internal_https" {
   name    = "pingds"
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
   name    = "${var.product_name}-${count.index}"
   type    = "A"                                
   zone_id = var.cloud_dns["aws"]["internal"].dns_zone_id 
   records = [aws_instance.pingds_server[count.index].private_ip]
   ttl     = 60
}

//resource "aws_route53_record" "pingds_lb_external" {
//
//   name    = "${var.dns_prefix}"
//   type    = "A"
//   zone_id = var.cloud_dns["aws"]["external"].dns_zone_id
//
//   alias {
//      evaluate_target_health = false
//      name                   = aws_lb.pingds.dns_name
//      zone_id                = aws_lb.pingds.zone_id
//   }
//}
