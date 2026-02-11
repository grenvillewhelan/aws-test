//data "aws_route53_zone" "accessidentifiedcloud" {
//
//   name         = var.dns_suffix["aws"]
//   provider     = aws.route53
//   private_zone = false
//}

data "aws_ami" "pingds_ami" {
  most_recent = true

  filter {
    name   = "name"

    values = [
      "${var.ami_version}"
    ]
  }

  filter {
    name   = "virtualization-type"
    values = [
      "hvm"
    ]
  }

  owners = [
    var.ami_account_owner
  ]
}

