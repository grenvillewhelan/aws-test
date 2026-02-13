resource "aws_iam_instance_profile" "pingam_server" {
   count = var.region_number == var.first_region_running ? 1 : 0
   name  = "${local.hyphenated_name}-server"
   role  = aws_iam_role.pingam_server_role[count.index].name
}

resource "aws_iam_role" "pingam_server_role" {
   count = var.region_number == var.first_region_running ? 1 : 0
   name = "${local.hyphenated_name}-server-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
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
      },
    ]
  })
}

resource "aws_iam_policy" "pingam_server_policy" {
   count = var.region_number == var.first_region_running ? 1 : 0
   name  = "${var.product_name}-server-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceEventNotificationAttributes",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "autoscaling:DescribeAutoScalingInstances"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "route53:ChangeResourceRecordSets"
        Effect   = "Allow"
        Resource = "arn:aws:route53:::hostedzone/${var.cloud_dns["aws"]["internal"].dns_zone_id}"
      },
      {
        Action = [
          "ec2:CreateTags" # TODO limit scope
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Effect = "Allow"
        Resource = [

          "arn:aws:ssm:*:${var.account_owner}:parameter/${var.customer_name}/${terraform.workspace}/deployment_status"
         ]
      },
      {
        Action = [
          "ssm:PutParameter",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:DeleteParameter",
          "ssm:GetParametersByPath"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:ssm:*:${var.account_owner}:parameter/${var.customer_name}/${terraform.workspace}/pingam/*/replication_leader"
        ]
      },
      # Kinesis / Elastic Search
      {
          "Sid": "VisualEditor1",
          "Effect": "Allow",
          "Action": [
              "cloudwatch:PutMetricData",
              "firehose:ListDeliveryStreams"
          ],
          "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:GetObject"
        ],
        "Resource": [
          "arn:aws:s3:::${var.aws_storage_account}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "pingam_server" {
   count      = var.region_number == var.first_region_running ? 1 : 0
   name       = "${local.hyphenated_name}-server-policy-attachment"
   policy_arn = aws_iam_policy.pingam_server_policy[count.index].arn
   roles      = ["${local.hyphenated_name}-server-role"]
}

resource "aws_iam_policy_attachment" "pingam_amazon_ssm_managed_instance_core" {
   count      = var.region_number == var.first_region_running ? 1 : 0
   name       = "AmazonSSMManagedInstanceCore"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  roles      = ["${local.hyphenated_name}-server-role"]
  depends_on = [ aws_iam_role.pingam_server_role ]

  lifecycle {
    ignore_changes = [ policy_arn, roles ]
  }
}
