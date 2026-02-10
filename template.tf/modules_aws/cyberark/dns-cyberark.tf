
resource "aws_route53_record" "cyberark_internal" {
   count   = var.number_servers
   name    = "cyberark-${count.index}"
   type    = "A" 
   zone_id = var.cloud_dns["aws"]["internal"].dns_zone_id
   records = [aws_instance.cyberark_server[count.index].private_ip]
   ttl     = 60
} 
