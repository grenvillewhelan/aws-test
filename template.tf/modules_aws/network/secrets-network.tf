resource "aws_ssm_parameter" "deployment_status" {
   name        = join("/", ["", var.customer_name, terraform.workspace, "deployment_status"])

   description = "Deployment Status"
   type        = "String"
   value       = var.deployment_status

   lifecycle {
      ignore_changes = [ value ]
   }
}

