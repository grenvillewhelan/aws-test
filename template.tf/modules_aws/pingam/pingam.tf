resource "aws_launch_template" "pingam" {
   name          = "pingam"
   image_id      = data.aws_ami.pingam_ami.id
   instance_type = var.instance_type
   update_default_version = true

   iam_instance_profile {
      name = "${local.hyphenated_name}-server"
   }

   user_data = base64encode(templatefile("${path.module}/scripts/pingam.sh", {
      CUSTOMER                       = var.customer_name
      ENVIRONMENT                    = terraform.workspace
      PRODUCT                        = "pingam"
      BUILD_VERSION                  = data.aws_ami.pingam_ami.name
      MODULE_VERSION                 = var.module_version
      REGION                         = var.my_manifest.region_name
      REGION_ALIAS                   = var.my_manifest.region_alias
      DNS_PREFIX                     = var.dns_prefix
      NUMBER_OF_SERVERS              = var.number_servers
      HEALTH_CHECK_GRACE_PERIOD      = var.health_check_grace_period
      CLOUD_DNS                      = replace(jsonencode(var.cloud_dns), "\"", "\\\"")
      DNS_SUFFIX                     = var.dns_suffix["aws"]
      CLUSTER                        = var.products[var.product_name].cluster
      PRODUCT_NAME                   = var.product_name
      CLOUD_PROVIDER                 = var.cloud_provider
      CLOUD_PROVIDERS                = replace(jsonencode(var.cloud_providers), "\"", "\\\"")
      HOSTED_ZONE_ID                 = var.cloud_dns["aws"]["internal"].dns_zone_id 
   }))

   key_name = var.aws_key_pair_id

   network_interfaces {
      security_groups = concat([var.security_group_ids[var.product_name]], aws_security_group.pingam[*].id)

      delete_on_termination       = true 
   }

  depends_on = [aws_iam_instance_profile.pingam_server ]
}

resource "aws_autoscaling_group" "pingam" {
   name                      = var.product_name
   max_size                  = var.number_servers
   min_size                  = var.number_servers
   desired_capacity          = var.number_servers

   health_check_type         = "ELB"
   health_check_grace_period = var.health_check_grace_period
   force_delete              = true

   target_group_arns = [aws_lb_target_group.pingam_https.arn ]


   launch_template {
      id = aws_launch_template.pingam.id
   }

   termination_policies = [
      "AllocationStrategy",
      "OldestInstance",
      "OldestLaunchConfiguration",
      "ClosestToNextInstanceHour"
   ]

   metrics_granularity = "1Minute"

   vpc_zone_identifier = var.subnet_ids

   instance_refresh {
      strategy = "Rolling"
   }

   tag {
      key                 = "ServerType"
      value               = "PingAM"
      propagate_at_launch = true
   }

   tag {
      key                 = "Name"
      value               = "pingam"
      propagate_at_launch = true
   }

   tag {
      key                 = "Environment"
      value               = terraform.workspace
      propagate_at_launch = true
   }

  depends_on = [ aws_iam_policy_attachment.pingam_server,
                 aws_lb_target_group.pingam_https
               ]

}
