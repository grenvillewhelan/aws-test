resource "aws_route53_record" "pingam-int-lb" {
   name    = var.dns_prefix
   type    = "CNAME"                                
   zone_id = var.cloud_dns["aws"]["internal"].dns_zone_id 
   records = [ aws_lb.pingam.dns_name ]
   ttl     = 60
}

