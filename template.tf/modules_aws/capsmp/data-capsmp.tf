data "aws_ami" "capsmp_ami" {

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
