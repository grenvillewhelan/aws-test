resource "aws_iam_instance_profile" "capsm_server" {
  count  = var.region_number == var.first_region_running ? 1 : 0
  name = "${local.hyphenated_name}-server"
  role = aws_iam_role.capsm_server_role[count.index].name
}

resource "aws_iam_role" "capsm_server_role" {
  count  = var.region_number == var.first_region_running ? 1 : 0
  name = "${local.hyphenated_name}-server-role"

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
