resource "aws_lb" "ingress_lb" {

   name               = "${var.my_manifest.region_alias}-${var.lb_type}-alb"
   load_balancer_type = "application"
   internal           = false
   subnets            = var.subnet_ids

   dynamic "access_logs" {

      for_each = var.ingress_logs_enabled ? ["run-once"] : []

      content {
         bucket  = aws_s3_bucket.ingress_lb_logs[count.index].id
         enabled = true
      }
   }

   security_groups = concat([var.security_group_ids["${var.lb_type}_ingress"]], aws_security_group.ingress[*].id)

   tags = {
      Name = "${var.my_manifest.region_alias}-${var.lb_type}-alb"
   }
}

resource "aws_lb_listener" "ingress_http" {

   load_balancer_arn = aws_lb.ingress_lb.arn
   port              = "80"
   protocol          = "HTTP"

   default_action {
      type = "redirect"

      redirect {
         port        = "443"
         protocol    = "HTTPS"
         status_code = "HTTP_301"
      }
   }

   depends_on = [ aws_lb.ingress_lb,
                  aws_acm_certificate_validation.certificate_validation ]
}

resource "aws_lb_listener" "ingress_https" {

   load_balancer_arn = aws_lb.ingress_lb.arn
   port              = "443"
   protocol          = "HTTPS"
   ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

   certificate_arn = aws_acm_certificate.internet.arn

   default_action {
      type = "fixed-response"

      fixed_response {
         content_type = "text/plain"
         message_body = "403: invalid address"
         status_code = "403"
      }
   }

   depends_on = [ aws_lb.ingress_lb,
                  aws_acm_certificate_validation.certificate_validation ]
}

resource "aws_alb_listener_rule" "apps" {

   for_each = local.prod_list

   listener_arn = aws_lb_listener.ingress_https.arn

   action {
      type             = "forward"
      target_group_arn = var.target_group_arns[lookup(each.value, "dns_prefix", "")][var.my_manifest.region_alias]
   }

   condition {
      host_header {
         values = [
            join(".", [lookup(each.value, "dns_prefix", ""), terraform.workspace, var.customer_name, var.dns_suffix["aws"]])
         ]
      }
   }
}

resource "aws_s3_bucket" "ingress_lb_logs" {
   count         = var.ingress_logs_enabled ? 1 : 0

   bucket = join(".", [lookup(var.products[var.product_name].parameters, "backup_prefix", "web-ingress-logs"), var.my_manifest.region_alias, terraform.workspace, var.customer_name, var.dns_suffix["aws"]])

   tags = {
      name = "${var.my_manifest.region_alias} ${var.lb_type} Ingress lb logs"
   }
}

resource "aws_s3_bucket_lifecycle_configuration" "ingress_lb_logs" {

   count         = var.ingress_logs_enabled ? 1 : 0

   bucket = aws_s3_bucket.ingress_lb_logs[count.index].id

   rule { 
      id = "2monthly_retention"
    
      expiration {
         days = 60
      }

      noncurrent_version_expiration {
         noncurrent_days = 60
      }

      status = "Enabled"
   }
}

resource "aws_s3_bucket_public_access_block" "ingress_lb_logs" {
   count         = var.ingress_logs_enabled ? 1 : 0

   bucket = aws_s3_bucket.ingress_lb_logs[count.index].id

   block_public_acls       = true
   block_public_policy     = true
   ignore_public_acls      = true
   restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "ingress_lb_logs" {
   count         = var.ingress_logs_enabled ? 1 : 0

   bucket = aws_s3_bucket.ingress_lb_logs[count.index].id

   rule {
      object_ownership = "BucketOwnerEnforced"
   }
}

resource "aws_s3_bucket_versioning" "ingress_lb_logs" {
   count = var.ingress_logs_enabled ? 1 : 0

   bucket = aws_s3_bucket.ingress_lb_logs[count.index].id
   versioning_configuration {
      status = "Enabled"
   }
}

resource "aws_s3_bucket_policy" "ingress_lb_logs" {
   count         = var.ingress_logs_enabled ? 1 : 0

   bucket = aws_s3_bucket.ingress_lb_logs[count.index].id
   policy = jsonencode({

    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          "AWS" = join(":", ["arn:aws:iam:", var.elb_account_id, "root"])
        }
        Action = [   
          "s3:PutObject"
        ]
        Resource = [ 
          join("/", [aws_s3_bucket.ingress_lb_logs[count.index].arn, "AWSLogs", var.account_owner, "*"])
        ]
      }
    ]
  }) 
}

locals {
   prod_list = {for x in compact([for x,y in var.products : var.my_manifest.products[x][terraform.workspace] > 0 && lookup(var.products[x].parameters, "web_ingress", false) ? x : ""]) : x => var.products[x].parameters}
}
