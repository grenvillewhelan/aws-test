resource "aws_lb" "pingds" {
  name               = "${var.product_name}-lb"
  load_balancer_type = "network"
  internal           = true
  subnets            = var.subnet_ids

  enable_cross_zone_load_balancing = true

  security_groups = concat([var.security_group_ids["${var.product_name}"]], aws_security_group.pingds[*].id)

  tags = {
    Name = "${var.my_manifest.region_alias}-${var.product_name}-lb"
  }
}

resource "aws_lb_target_group" "pingds_ldaps" {
  name        = "${var.product_name}-ldaps"
  port        = 1636
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled           = true
    port              = "8443"
    protocol          = "HTTPS"
    path              = "/available-state"
    interval          = 10
    healthy_threshold = 3
  }
}

resource "aws_lb_target_group" "pingds_https" {
  name        = "${var.product_name}-https"
  port        = 8443
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled           = true
    port              = "8443"
    protocol          = "HTTPS"
    path              = "/available-state"
    interval          = 10
    healthy_threshold = 3
  }
}

resource "aws_lb_target_group_attachment" "pingds_ldaps" {
  count            = var.number_servers
  target_group_arn = aws_lb_target_group.pingds_ldaps.id
  target_id        = aws_instance.pingds_server[count.index].id
  port             = 1636

  depends_on = [ aws_lb_target_group.pingds_ldaps ]
}

resource "aws_lb_target_group_attachment" "pingds_https" {
  count            = var.number_servers
  target_group_arn = aws_lb_target_group.pingds_https.id
  target_id        = aws_instance.pingds_server[count.index].id
  port             = 8443

  depends_on = [ aws_lb_target_group.pingds_https ]
}

resource "aws_lb_listener" "pingds_ldaps" {
  load_balancer_arn = aws_lb.pingds.arn
  port              = "1636"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pingds_ldaps.arn
  }

  depends_on = [
                 aws_lb.pingds,
                 aws_lb_target_group.pingds_ldaps
  ]
}

resource "aws_lb_listener" "pingds_https" {
  load_balancer_arn = aws_lb.pingds.arn
  port              = "8443"
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  certificate_arn = aws_acm_certificate_validation.pingds_cert_validation.certificate_arn


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pingds_https.arn
  }

  depends_on = [
                  aws_lb.pingds,
                  aws_lb_target_group.pingds_https
  ]
}

resource "aws_acm_certificate" "pingds" {
   domain_name       = join(".", [lookup(var.products[var.product_name].parameters, "dns_prefix", "ldaps"), "int", terraform.workspace, var.dns_suffix["aws"]])
   validation_method = "DNS"

   lifecycle {
      create_before_destroy = true
   }

   tags = {
       Name = join(".", [lookup(var.products[var.product_name].parameters, "dns_prefix", "ldaps"), "int", terraform.workspace, var.dns_suffix["aws"]])
   }
}

//resource "aws_route53_record" "r53_pingds_cert_validation" {
//   count    = var.region_number == var.first_region_running ? 1 : 0
//   name     = tolist(aws_acm_certificate.pingds.domain_validation_options)[count.index].resource_record_name
//   records  = [tolist(aws_acm_certificate.pingds.domain_validation_options)[count.index].resource_record_value]
//   type     = tolist(aws_acm_certificate.pingds.domain_validation_options)[count.index].resource_record_type
//   zone_id  = var.cloud_dns["aws"]["external"].dns_zone_id
//
//   ttl      = 60
//   provider = aws.route53
//}

resource "aws_route53_record" "r53_pingds_cert_validation" {
  # Use for_each to handle all validation options safely
  for_each = {
    for dvo in aws_acm_certificate.pingds.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.cloud_dns["aws"]["external"].dns_zone_id
  
  provider        = aws.route53
}

resource "aws_acm_certificate_validation" "pingds_cert_validation" {
   # Use values() to turn the map into a list, then grab the fqdn
   certificate_arn         = aws_acm_certificate.pingds.arn
   validation_record_fqdns = [for record in aws_route53_record.r53_pingds_cert_validation : record.fqdn]
}

//resource "aws_acm_certificate_validation" "pingds_cert_validation" {
//   count                   = var.region_number == var.first_region_running ? 1 : 0
//   certificate_arn         = aws_acm_certificate.pingds.arn
//   validation_record_fqdns = aws_route53_record.r53_pingds_cert_validation[*].fqdn
//}

# DNS

locals {
  pd_dns_prefix = "ldap"
  dir_prefix    = "dir"
  backup_stagger_time = "30"

//  region_backup_mins = try(var.products[var.product_name].parameters["pingds_ldif_backup_time"], "03:00")
}
