resource "aws_lb" "internal_pingds_lb" {
   name                = "${var.my_manifest.region_alias}-internal-${lookup(var.products[var.product_name].parameters, "dns_prefix", "ldap")}"
   load_balancer_type  = "application"
   internal            = true
   subnets             = var.subnet_ids
   security_groups     = concat([var.security_group_ids[var.product_name]], aws_security_group.pingds[*].id)

   tags = {
      Name = "${var.my_manifest.region_alias}-internal-${var.product_name}"
   }
 }

resource "aws_lb_listener" "pingds-https" {
   load_balancer_arn = aws_lb.internal_pingds_lb.arn

   port              = lookup(var.products[var.product_name].parameters, "frontend_port", 8443)
   protocol        = "HTTPS"
   ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"

   certificate_arn   = aws_acm_certificate.pingds.arn

   default_action {
      type = "forward"

      target_group_arn = aws_lb_target_group.pingds_internal_lb.arn
   }
}

resource "aws_lb_target_group" "pingds_internal_lb" {
   name     = "${var.my_manifest.region_alias}-${lookup(var.products[var.product_name].parameters, "dns_prefix", "ldap")}-tg"
   port     = 8443
   protocol = "HTTPS"
   vpc_id   = var.vpc_id

   health_check {
      enabled  = true
      path     = lookup(var.products[var.product_name].parameters, "healthcheck_path", "/available-state")
      interval = lookup(var.products[var.product_name].parameters, "healthcheck_interval", 10)
      protocol = "HTTPS"
   }

   stickiness {
      type = "lb_cookie"
   }

   lifecycle {
      ignore_changes = [ name, tags ]
   }
}

resource "aws_lb_target_group_attachment" "pingds_internal_https" {
  count            = var.number_servers
  target_group_arn = aws_lb_target_group.pingds_internal_lb.id
  target_id        = aws_instance.pingds_server[count.index].id
  port             = 8443

  depends_on = [ aws_lb_target_group.pingds_https ]
}

resource "aws_lb_target_group" "pingds" {
   name     = "${var.my_manifest.region_alias}-${var.product_name}"
   port     = lookup(var.products[var.product_name].parameters, "frontend_port", 8443)
   protocol = "HTTPS"
   vpc_id   = var.vpc_id

   health_check {
      enabled  = true
      path     = lookup(var.products[var.product_name].parameters, "healthcheck_path", "/available-state")
      interval = lookup(var.products[var.product_name].parameters, "healthcheck_interval", 10)
      protocol = "HTTPS"
   }

   stickiness {
      type = "lb_cookie"
   }

   lifecycle {
      ignore_changes = [ name, tags ]
   }
}

resource "aws_lb_target_group_attachment" "pingds" {
  count            = var.number_servers
  target_group_arn = aws_lb_target_group.pingds.id
  target_id        = aws_instance.pingds_server[count.index].id
  port             = 8443

  depends_on = [ aws_lb_target_group.pingds ]
}
