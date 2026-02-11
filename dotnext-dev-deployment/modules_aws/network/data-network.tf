//data "aws_route53_zone" "route53zone" {
//
//   name         = var.dns_suffix["aws"]
//   provider     = aws.route53
//   private_zone = false
//}

data "aws_route53_delegation_set" "dotnext" { 
  id = var.dns_delegation["aws"]
}
