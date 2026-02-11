resource "aws_iam_instance_profile" "pingds_server" {
   count = var.region_number == var.first_region_running ? 1 : 0
   name  = "${local.hyphenated_name}-server"
   role  = aws_iam_role.pingds_server_role[count.index].name
}

resource "aws_iam_role" "pingds_server_role" {
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

resource "aws_iam_policy" "pingds_server_policy" {
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

          "arn:aws:ssm:*:${var.account_owner}:parameter/${var.customer_name}/${terraform.workspace}/pingds/*/replication_leader",
          "arn:aws:ssm:*:${var.account_owner}:parameter/${var.customer_name}/${terraform.workspace}/pingds/*/pingds_replication_admin_password",
          "arn:aws:ssm:*:${var.account_owner}:parameter/${var.customer_name}/${terraform.workspace}/pingds/*/pingds_pingfed_oauth_client_username",
          "arn:aws:ssm:*:${var.account_owner}:parameter/${var.customer_name}/${terraform.workspace}/pingds/*/pingds_pingfed_oauth_client_password",
          "arn:aws:ssm:*:${var.account_owner}:parameter/${var.customer_name}/${terraform.workspace}/pingds/*/binary_backup_time"
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
          "Sid": "VisualEditor0",
          "Effect": "Allow",
          "Action": [
              "firehose:PutRecord",
              "firehose:PutRecordBatch"
          ],
          "Resource": [
              "arn:aws:firehose:*:${var.account_owner}:deliverystream/pingds-access",
              "arn:aws:firehose:*:${var.account_owner}:deliverystream/pingds-errors",
              "arn:aws:firehose:*:${var.account_owner}:deliverystream/pingds-failedops"
          ]
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

resource "aws_iam_policy_attachment" "pingds_server" {
   count      = var.region_number == var.first_region_running ? 1 : 0
   name       = "${local.hyphenated_name}-server-policy-attachment"
   policy_arn = aws_iam_policy.pingds_server_policy[count.index].arn
   roles      = ["${local.hyphenated_name}-server-role"]
}

resource "aws_iam_policy_attachment" "pingds_amazon_ssm_managed_instance_core" {
   count      = var.region_number == var.first_region_running ? 1 : 0
   name       = "AmazonSSMManagedInstanceCore"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  roles      = ["${local.hyphenated_name}-server-role"]
  depends_on = [ aws_iam_role.pingds_server_role ]

  lifecycle {
    ignore_changes = [ policy_arn, roles ]
  }
}
