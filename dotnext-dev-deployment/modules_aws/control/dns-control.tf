resource "aws_route53_record" "control" {

   name    = var.product_name
   type    = "A"
   zone_id = var.cloud_dns["aws"]["external"].dns_zone_id
   records = [aws_instance.control_server.public_ip]
   ttl     = 60
}

resource "aws_route53_record" "control_internal" {

   name    = var.product_name
   type    = "A" 
   zone_id = var.cloud_dns["aws"]["internal"].dns_zone_id
   records = [aws_instance.control_server.private_ip]
   ttl     = 60
} 
