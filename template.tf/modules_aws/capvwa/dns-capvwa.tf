
resource "aws_route53_record" "capvwa_internal" {
   count   = var.number_servers
   name    = "${var.product_name}-${count.index}"
   type    = "A" 
   zone_id = var.cloud_dns["aws"]["internal"].dns_zone_id
   records = [aws_instance.capvwa_server[count.index].private_ip]
   ttl     = 60
} 

resource "aws_route53_record" "capvwa" {
   count   = var.number_servers
   name    = "${var.product_name}-${count.index}"
   type    = "A"
   zone_id = var.cloud_dns["aws"]["external"].dns_zone_id
   records = [aws_instance.capvwa_server[count.index].public_ip]
   ttl     = 60
}

resource "aws_route53_record" "capvwa_lb_internal_https" {
   name    = "${var.dns_prefix}"
   type    = "A"
   zone_id = var.cloud_dns["aws"]["internal"].dns_zone_id

   alias {
      evaluate_target_health = false
      name                   = aws_lb.capvwa.dns_name
      zone_id                = aws_lb.capvwa.zone_id
   }
}

resource "aws_route53_record" "capvwa_lb_external_https" {

   name    = "${var.dns_prefix}"
   type    = "A"
   zone_id = var.cloud_dns["aws"]["external"].dns_zone_id

   alias {
      evaluate_target_health = false
      name                   = aws_lb.capvwa.dns_name
      zone_id                = aws_lb.capvwa.zone_id
   }
}

