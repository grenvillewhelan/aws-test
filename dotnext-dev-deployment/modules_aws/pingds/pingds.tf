resource "aws_instance" "pingds_server" {
   count         = var.number_servers
   subnet_id     = element(var.subnet_ids, count.index%length(var.subnet_ids))
   instance_type = var.instance_type
   key_name      = var.aws_key_pair_id
   availability_zone = join("", [var.my_manifest.region_name, var.az[count.index % length(var.az)]])

  iam_instance_profile =   "${local.hyphenated_name}-server"

  ami = data.aws_ami.pingds_ami.id

  user_data = templatefile("${path.module}/scripts/pingds.sh", {
        BUILD_VERSION                          = data.aws_ami.pingds_ami.name
        MODULE_VERSION                         = var.module_version
        REGION                                 = var.my_manifest.region_name
        REGION_ALIAS                           = var.my_manifest.region_alias
        PRODUCT                                = "pingds"
        PRIMARY_PARAMETER_STORES               = replace(jsonencode(var.primary_parameter_stores), "\"", "\\\"")
        SERVER_INSTANCE                        = count.index + 1
        LOG_RETENTION                          = try(var.products[var.product_name].parameters["pingds_log_retention"], "7")
        CUSTOMER                               = var.customer_name
        ENVIRONMENT                            = terraform.workspace
        PINGDIRECTORY_BASE_DN                  = replace("dc=${terraform.workspace},dc=${var.customer_name},dc=${var.dns_suffix["aws"]}", ".", ",dc=")
        PINGDIRECTORY_UNDERSCORE_BASE_DN       = replace("dc_${terraform.workspace}_dc_${var.customer_name}_dc_${var.dns_suffix["aws"]}", ".", "_dc_")

        DNS_SUFFIX                             = var.dns_suffix["aws"]
        PD_BACKUP_TIME                         = try(var.products[var.product_name].parameters["pingds_backup_time"], "02:00")
        LDIF_BACKUP_TIME                       = try(var.products[var.product_name].parameters["pingds_ldif_backup_time"], "03:00")
        PD_BACKUP_STAGGER_MINS                 = local.backup_stagger_time
        REGION_BACKUP_START_DELAY              = var.region_number * var.number_servers
        CLUSTER                                = var.products[var.product_name].cluster
        PRODUCT_NAME                           = var.product_name
        BACKUP_PREFIX                          = lookup(var.products[var.product_name].parameters, "backup_prefix", "pd")
        PF_CLUSTER                             = lookup(var.products[var.product_name].parameters, "pingfed_cluster", "none")
        REGION_LIST                            = replace(jsonencode(var.region_list), "\"", "\\\"")
        TENANT_ID                              = var.tenant_id
        CLIENT_ID                              = var.client_id
        CLIENT_SECRET                          = var.client_secret
        CLOUD_PROVIDER                         = var.cloud_provider
        CLOUD_PROVIDERS                        = replace(jsonencode(var.cloud_providers), "\"", "\\\"")
        CLOUD_DNS                              = replace(jsonencode(var.cloud_dns), "\"", "\\\"")
        SUBSCRIPTION_ID                        = var.subscription_id
      })

  disable_api_termination = var.termination_protection

  ebs_optimized = true

  vpc_security_group_ids = concat([var.security_group_ids["${var.product_name}"]], aws_security_group.pingds[*].id)

  tags = {
    Name       = join ("",["${var.product_name}-",count.index])
    ServerType = var.product_name
    Status     = "unreplicated"
    RegionAlias  = "${var.my_manifest.region_alias}"
  }

  depends_on = [
                  aws_iam_policy_attachment.pingds_server
  ]

  lifecycle {
    ignore_changes = [ tags, tags_all, ami, user_data ]
  }
}

resource "aws_lb" "pingds" {
  name               = "${var.my_manifest.region_alias}-${var.product_name}-lb"
  load_balancer_type = "network"
  internal           = true
  subnets            = var.subnet_ids

  enable_cross_zone_load_balancing = true

  security_groups = concat([var.security_group_ids["${var.product_name}"]], aws_security_group.pingds[*].id)

  tags = {
    Name = "${var.my_manifest.region_alias}-${var.product_name}-lb"
  }
}

resource "aws_lb_target_group" "pingds_ldaps" {
  name        = "${var.my_manifest.region_alias}-${var.product_name}-ldaps"
  port        = 1636
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    port              = "8443"
    protocol          = "HTTPS"
    path              = "/available-state"
    interval          = 10
    healthy_threshold = 3
  }
}

resource "aws_lb_target_group" "pingds_https" {
  name        = "${var.my_manifest.region_alias}-${var.product_name}-https"
  port        = 8443
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    port              = "8443"
    protocol          = "HTTPS"
    path              = "/available-state"
    interval          = 10
    healthy_threshold = 3
  }
}

resource "aws_lb_target_group_attachment" "pingds_ldaps" {
  count            = var.number_servers
  target_group_arn = aws_lb_target_group.pingds_ldaps.id
  target_id        = aws_instance.pingds_server[count.index].id
  port             = 1636

  depends_on = [ aws_lb_target_group.pingds_ldaps ]
}

resource "aws_lb_target_group_attachment" "pingds_https" {
  count            = var.number_servers
  target_group_arn = aws_lb_target_group.pingds_https.id
  target_id        = aws_instance.pingds_server[count.index].id
  port             = 8443

  depends_on = [ aws_lb_target_group.pingds_https ]
}

resource "aws_lb_listener" "pingds_ldaps" {
  load_balancer_arn = aws_lb.pingds.arn
  port              = "1636"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pingds_ldaps.arn
  }

  depends_on = [
                 aws_lb.pingds,
                 aws_lb_target_group.pingds_ldaps
  ]
}

//resource "aws_lb_listener" "pingds_https" {
//  load_balancer_arn = aws_lb.pingds.arn
//  port              = "8443"
//  protocol          = "TLS"
//  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
//
//  certificate_arn = aws_acm_certificate.pingds.arn
//
//  default_action {
//    type             = "forward"
//    target_group_arn = aws_lb_target_group.pingds_https.arn
//  }
//
//  depends_on = [
//                  aws_lb.pingds,
//                  aws_lb_target_group.pingds_https
//  ]
//}

//resource "aws_acm_certificate" "pingds" {
//   domain_name       = join(".", [lookup(var.products[var.product_name].parameters, "dns_prefix", "ldap"), "int", terraform.workspace, var.customer_name, var.dns_suffix["aws"]])
//   validation_method = "DNS"
//
//   lifecycle {
//      create_before_destroy = true
//   }
//
//   tags = {
//       Name = join(".", [lookup(var.products[var.product_name].parameters, "dns_prefix", "ldap"), "int", terraform.workspace, var.customer_name, var.dns_suffix["aws"]])
//   }
//}

//resource "aws_route53_record" "r53_pingds_cert_validation" {
//   count    = var.region_number == var.first_region_running ? 1 : 0
//   name     = tolist(aws_acm_certificate.pingds.domain_validation_options)[count.index].resource_record_name
//   records  = [tolist(aws_acm_certificate.pingds.domain_validation_options)[count.index].resource_record_value]
//   type     = tolist(aws_acm_certificate.pingds.domain_validation_options)[count.index].resource_record_type
//   zone_id  = var.cloud_dns["aws"]["external"].dns_zone_id
//
//   ttl      = 60
//   provider = aws.route53
//}

//resource "aws_acm_certificate_validation" "pingds_cert_validation" {
//   count                   = var.region_number == var.first_region_running ? 1 : 0
//   certificate_arn         = aws_acm_certificate.pingds.arn
//   validation_record_fqdns = aws_route53_record.r53_pingds_cert_validation[*].fqdn
//}

# DNS

locals {
  pd_dns_prefix = "ldap"
  dir_prefix    = "dir"
  backup_stagger_time = "30"

//  region_backup_mins = try(var.products[var.product_name].parameters["pingds_ldif_backup_time"], "03:00")
}
