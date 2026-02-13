resource "aws_lb" "capvwa" {
  name               = "${var.product_name}-lb"
  load_balancer_type = "network"
  internal           = true
  subnets            = var.subnet_ids

  enable_cross_zone_load_balancing = true

  security_groups = concat([var.security_group_ids["${var.product_name}"]], aws_security_group.capvwa[*].id)

  tags = {
    Name = "${var.my_manifest.region_alias}-${var.product_name}-lb"
  }
}

resource "aws_lb_target_group" "capvwa_https" {
  name        = "${var.product_name}-https"
  port        = 8443
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled           = true
    port              = "8443"
    protocol          = "HTTPS"
    path              = "/PasswordVault/HealthCheck.php"
    interval          = 10
    healthy_threshold = 3
  }
}

resource "aws_lb_target_group_attachment" "capvwa_https" {
  count            = var.number_servers
  target_group_arn = aws_lb_target_group.capvwa_https.id
  target_id        = aws_instance.capvwa_server[count.index].id
  port             = 8443

  depends_on = [ aws_lb_target_group.capvwa_https ]
}

resource "aws_lb_listener" "capvwa_https" {
  load_balancer_arn = aws_lb.capvwa.arn
  port              = "443"
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  certificate_arn = aws_acm_certificate_validation.capvwa_cert_validation.certificate_arn


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.capvwa_https.arn
  }

  depends_on = [
                  aws_lb.capvwa,
                  aws_lb_target_group.capvwa_https
  ]
}

resource "aws_acm_certificate" "capvwa" {
   domain_name       = join(".", [lookup(var.products[var.product_name].parameters, "dns_prefix", "pam"), "int", terraform.workspace, var.dns_suffix["aws"]])
   validation_method = "DNS"

   lifecycle {
      create_before_destroy = true
   }

   tags = {
       Name = join(".", [lookup(var.products[var.product_name].parameters, "dns_prefix", "pam"), "int", terraform.workspace, var.dns_suffix["aws"]])
   }
}

resource "aws_route53_record" "r53_capvwa_cert_validation" {
  # Use for_each to handle all validation options safely
  for_each = {
    for dvo in aws_acm_certificate.capvwa.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "capvwa_cert_validation" {
   # Use values() to turn the map into a list, then grab the fqdn
   certificate_arn         = aws_acm_certificate.capvwa.arn
   validation_record_fqdns = [for record in aws_route53_record.r53_capvwa_cert_validation : record.fqdn]
}

