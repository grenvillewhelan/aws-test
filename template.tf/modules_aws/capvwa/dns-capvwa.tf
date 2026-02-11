
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
