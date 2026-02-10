output "ingress_lb_listener_https_arn" {
  value = aws_lb_listener.ingress_https.arn
}

output "ingress_lb_internet_console_arn" {
   value = aws_lb.ingress_lb.arn
}

output "ingress_lb_internet_dns_name" {
  value = aws_lb.ingress_lb.dns_name
}

output "ingress_lb_internet_zone_id" {
  value = aws_lb.ingress_lb.zone_id
}

output "certificate_internet_arn" {
  value = aws_acm_certificate.internet.arn
}
