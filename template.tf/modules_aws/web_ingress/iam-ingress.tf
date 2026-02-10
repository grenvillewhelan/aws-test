resource "aws_iam_instance_profile" "ingress" {
   count = var.region_number == var.first_region_running ? 1 : 0
   name = "${var.lb_type}-ingress-server"
   role = aws_iam_role.ingress_role[count.index].name
}

resource "aws_iam_role" "ingress_role" {
   count = var.region_number == var.first_region_running ? 1 : 0
   name = "${var.lb_type}-ingress-role"

   assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
         {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Sid    = ""
            Principal = {
               Service = "ec2.amazonaws.com"
            }
         }
      ]

   })
}
