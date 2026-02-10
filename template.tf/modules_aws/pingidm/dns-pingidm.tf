resource "aws_route53_record" "pingidm-int" {
   count   = var.number_servers
//   name    = join (".", [aws_instance.pingidm_server[count.index].id, var.my_manifest.region_alias])
   name    = "pingidm-${count.index}"
   type    = "A"                                
   zone_id = var.cloud_dns["aws"]["internal"].dns_zone_id 
   records = [aws_instance.pingidm_server[count.index].private_ip]
   ttl     = 60
}
