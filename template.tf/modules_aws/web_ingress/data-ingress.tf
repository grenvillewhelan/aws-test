data "aws_ssm_parameter" "customer_private_key" {
   count = var.https_customer_certificate ? 1 : 0

   name  = join("/", ["", var.customer_name, terraform.workspace, "customer_private_key"])
}

data "aws_ssm_parameter" "customer_certificate" {
   count = var.https_customer_certificate ? 1 : 0
   name  = join("/", ["", var.customer_name, terraform.workspace, "customer_certificate"])
}

data "aws_ssm_parameter" "customer_certificate_chain" {
   count = var.https_customer_certificate ? 1 : 0

   name  = join("/", ["", var.customer_name, terraform.workspace, "customer_certificate_chain"])
}
