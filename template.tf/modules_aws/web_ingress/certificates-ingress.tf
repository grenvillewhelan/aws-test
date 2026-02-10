resource "aws_acm_certificate" "internet" {

   domain_name       = join(".", [terraform.workspace, var.customer_name, var.dns_suffix["aws"]])
   validation_method = "DNS"

   subject_alternative_names = var.san_list

   lifecycle {
     create_before_destroy = true
   }

   tags = {
     Name = join(".", [terraform.workspace, var.customer_name, var.dns_suffix["aws"]])
   }
}

resource "aws_route53_record" "route53_certificate_validation" {
   count    = var.lb_type == "web" && var.region_number == var.first_region_running ? length(var.san_list) + 1 : 0

   name     = tolist(aws_acm_certificate.internet.domain_validation_options)[count.index].resource_record_name
   records  = [tolist(aws_acm_certificate.internet.domain_validation_options)[count.index].resource_record_value]
   type     = tolist(aws_acm_certificate.internet.domain_validation_options)[count.index].resource_record_type

   zone_id  = var.cloud_dns["aws"]["external"].dns_zone_id

   ttl      = 60
   provider = aws.route53
}

resource "aws_acm_certificate_validation" "certificate_validation" {
   count    = var.lb_type == "web" && var.region_number == var.first_region_running ? 1 : 0

   certificate_arn         = aws_acm_certificate.internet.arn
   validation_record_fqdns = aws_route53_record.route53_certificate_validation[*].fqdn

   depends_on = [aws_route53_record.route53_certificate_validation]
}
