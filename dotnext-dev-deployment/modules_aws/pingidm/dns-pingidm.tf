resource "aws_route53_record" "pingidm-int" {
   count   = var.number_servers
   name    = "${var.product_name}-${count.index}"
   type    = "A"                                
   zone_id = var.cloud_dns["aws"]["internal"].dns_zone_id 
   records = [aws_instance.pingidm_server[count.index].private_ip]
   ttl     = 60
}

//resource "aws_route53_record" "pingidm" {
//   count   = var.number_servers
//   name    = "${var.product_name}-${count.index}"
//   type    = "A"
//   zone_id = var.cloud_dns["aws"]["external"].dns_zone_id
//   records = [aws_instance.pingidm_server[count.index].public_ip]
//   ttl     = 60
//}
