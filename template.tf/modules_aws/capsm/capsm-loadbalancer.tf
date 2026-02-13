resource "aws_lb" "capsm" {
  name               = "${var.product_name}-lb"
  load_balancer_type = "network"
  internal           = true
  subnets            = var.subnet_ids

  enable_cross_zone_load_balancing = true

  security_groups = concat([var.security_group_ids["${var.product_name}"]], aws_security_group.capsm[*].id)

  tags = {
    Name = "${var.my_manifest.region_alias}-${var.product_name}-lb"
  }
}

resource "aws_lb_target_group" "capsm_https" {
  name        = "${var.product_name}-https"
  port        = 443
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled           = true
    port              = "443"
    protocol          = "HTTPS"
    path              = "/psm/api/health"
    interval          = 10
    healthy_threshold = 3
  }
}

resource "aws_lb_target_group_attachment" "capsm_https" {
  count            = var.number_servers
  target_group_arn = aws_lb_target_group.capsm_https.id
  target_id        = aws_instance.capsm_server[count.index].id
  port             = 443

  depends_on = [ aws_lb_target_group.capsm_https ]
}

resource "aws_lb_listener" "capsm_https" {
  load_balancer_arn = aws_lb.capsm.arn
  port              = "443"
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  certificate_arn = aws_acm_certificate_validation.capsm_cert_validation.certificate_arn


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.capsm_https.arn
  }

  depends_on = [
                  aws_lb.capsm,
                  aws_lb_target_group.capsm_https
  ]
}

resource "aws_acm_certificate" "capsm" {
   domain_name       = join(".", [lookup(var.products[var.product_name].parameters, "dns_prefix", "pam"), "int", terraform.workspace, var.dns_suffix["aws"]])
   validation_method = "DNS"

   lifecycle {
      create_before_destroy = true
   }

   tags = {
       Name = join(".", [lookup(var.products[var.product_name].parameters, "dns_prefix", "pam"), "int", terraform.workspace, var.dns_suffix["aws"]])
   }
}

resource "aws_route53_record" "r53_capsm_cert_validation" {
  # Use for_each to handle all validation options safely
  for_each = {
    for dvo in aws_acm_certificate.capsm.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "capsm_cert_validation" {
   # Use values() to turn the map into a list, then grab the fqdn
   certificate_arn         = aws_acm_certificate.capsm.arn
   validation_record_fqdns = [for record in aws_route53_record.r53_capsm_cert_validation : record.fqdn]
}

