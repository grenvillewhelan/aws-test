resource "aws_lb" "pingam" {
  name               = "${var.product_name}-lb"
  load_balancer_type = "application"
  internal           = true
  subnets            = var.subnet_ids

  enable_cross_zone_load_balancing = true

  security_groups = concat([var.security_group_ids["${var.product_name}"]], aws_security_group.pingam[*].id)

  tags = {
    Name = "${var.product_name}-lb"
  }
}

resource "aws_lb_target_group" "pingam_https" {
  name        = "${var.product_name}-https"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = var.vpc_id

  health_check {
    protocol            = "HTTPS"
    port                = "8443"
    path              = "/am/isAlive.jsp"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "pingam_https" {
  load_balancer_arn = aws_lb.pingam.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  certificate_arn = aws_acm_certificate_validation.pingam_cert_validation.certificate_arn


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pingam_https.arn
  }

  depends_on = [
                  aws_lb.pingam,
                  aws_lb_target_group.pingam_https
  ]
}

resource "aws_acm_certificate" "pingam" {
   domain_name       = join(".", [lookup(var.products[var.product_name].parameters, "dns_prefix", "ldaps"), "int", terraform.workspace, var.dns_suffix["aws"]])
   validation_method = "DNS"

   lifecycle {
      create_before_destroy = true
   }

   tags = {
       Name = join(".", [lookup(var.products[var.product_name].parameters, "dns_prefix", "ldaps"), "int", terraform.workspace, var.dns_suffix["aws"]])
   }
}

resource "aws_route53_record" "r53_pingam_cert_validation" {
  # Use for_each to handle all validation options safely
  for_each = {
    for dvo in aws_acm_certificate.pingam.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "pingam_cert_validation" {
   # Use values() to turn the map into a list, then grab the fqdn
   certificate_arn         = aws_acm_certificate.pingam.arn
   validation_record_fqdns = [for record in aws_route53_record.r53_pingam_cert_validation : record.fqdn]
}

//resource "aws_acm_certificate_validation" "pingam_cert_validation" {
//   count                   = var.region_number == var.first_region_running ? 1 : 0
//   certificate_arn         = aws_acm_certificate.pingam.arn
//   validation_record_fqdns = aws_route53_record.r53_pingam_cert_validation[*].fqdn
//}

# DNS

locals {
  pd_dns_prefix = "ldap"
  dir_prefix    = "dir"
  backup_stagger_time = "30"

//  region_backup_mins = try(var.products[var.product_name].parameters["pingam_ldif_backup_time"], "03:00")
}
