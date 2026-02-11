resource "aws_instance" "pingam_server" {
   count         = var.number_servers
   subnet_id     = element(var.subnet_ids, count.index%length(var.subnet_ids))
   instance_type = var.instance_type
   key_name      = var.aws_key_pair_id
   availability_zone = join("", [var.my_manifest.region_name, var.az[count.index % length(var.az)]])

  iam_instance_profile =   "${local.hyphenated_name}-server"

  ami = data.aws_ami.pingam_ami.id

  user_data = templatefile("${path.module}/scripts/pingam.sh", {
        BUILD_VERSION                          = data.aws_ami.pingam_ami.name
        MODULE_VERSION                         = var.module_version
        REGION                                 = var.my_manifest.region_name
        REGION_ALIAS                           = var.my_manifest.region_alias
        PRODUCT                                = "pingam"
        PRIMARY_PARAMETER_STORES               = replace(jsonencode(var.primary_parameter_stores), "\"", "\\\"")
        SERVER_INSTANCE                        = count.index + 1
        LOG_RETENTION                          = try(var.products[var.product_name].parameters["pingam_log_retention"], "7")
        CUSTOMER                               = var.customer_name
        ENVIRONMENT                            = terraform.workspace
        PINGDIRECTORY_BASE_DN                  = replace("dc=${terraform.workspace},dc=${var.customer_name},dc=${var.dns_suffix["aws"]}", ".", ",dc=")
        PINGDIRECTORY_UNDERSCORE_BASE_DN       = replace("dc_${terraform.workspace}_dc_${var.customer_name}_dc_${var.dns_suffix["aws"]}", ".", "_dc_")

        DNS_SUFFIX                             = var.dns_suffix["aws"]
        PD_BACKUP_TIME                         = try(var.products[var.product_name].parameters["pingam_backup_time"], "02:00")
        LDIF_BACKUP_TIME                       = try(var.products[var.product_name].parameters["pingam_ldif_backup_time"], "03:00")
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

  vpc_security_group_ids = concat([var.security_group_ids["${var.product_name}"]], aws_security_group.pingam[*].id)

  tags = {
    Name       = join ("",["${var.product_name}-",count.index])
    ServerType = var.product_name
    Status     = "unreplicated"
    RegionAlias  = "${var.my_manifest.region_alias}"
  }

  depends_on = [
                  aws_iam_policy_attachment.pingam_server
  ]

  lifecycle {
    ignore_changes = [ tags, tags_all, ami, user_data ]
  }
}

# DNS

locals {
  pd_dns_prefix = "ldap"
  dir_prefix    = "dir"
  backup_stagger_time = "30"

//  region_backup_mins = try(var.products[var.product_name].parameters["pingam_ldif_backup_time"], "03:00")
}
