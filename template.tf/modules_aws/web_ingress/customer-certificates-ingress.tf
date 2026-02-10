resource "aws_acm_certificate" "customer_certificate" {
   count             = var.https_customer_certificate ? 1 : 0

   private_key       = data.aws_ssm_parameter.customer_private_key[count.index].value
   certificate_body  = data.aws_ssm_parameter.customer_certificate[count.index].value
   certificate_chain = data.aws_ssm_parameter.customer_certificate_chain[count.index].value

   lifecycle {
     create_before_destroy = true
   }
}

resource "aws_alb_listener_certificate" "customer_certificate" {
   count             = var.https_customer_certificate ? 1 : 0

   certificate_arn   = aws_acm_certificate.customer_certificate[count.index].arn
   listener_arn      = aws_lb_listener.ingress_https[count.index].arn
}
