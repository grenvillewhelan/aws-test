module "cacpm_ireland" {
   source                               = "./modules_aws/cacpm"
   module                               = "cacpm"
   products                             = var.products
   product_name                         = "cacpm"
   instance_type                        = var.products["cacpm"].instance["aws"][terraform.workspace]
   account_owner                        = var.account_owner["aws"][terraform.workspace]
   ami_account_owner                    = var.ami_account_owner["aws"][terraform.workspace]
   ami_version                          = "${var.products["cacpm"].ami["aws"][terraform.workspace]}-v1.0.0e"
   aws_key_pair_id                      = aws_key_pair.ireland_admin_access.id
   module_version                       = "TBA"
   products_installed                   = local.products_installed["aws"]
   vpc_id                               = local.vpcs["ireland"]
   customer_name                        = var.customer_name
   dns_suffix                           = var.dns_suffix
   termination_protection               = var.termination_protection
   cidr_blocks                          = local.subnet_cidr_blocks
   security_group_ids                   = local.security_group_ids["ireland"]
   first_region_running                 = compact([for index, entry in var.manifest["aws"] : entry.products["cacpm"][terraform.workspace] > 0 ? index : ""] )[0]
   number_of_regions                    = length(var.manifest["aws"])
   region_number                        = 0
   my_manifest                          = var.manifest["aws"][0]
   number_servers                       = var.manifest["aws"][0].products["cacpm"][terraform.workspace]
   subnet_ids                           = local.subnet_ids["ireland"][var.products["cacpm"].subnet]
   health_check_grace_period = 300
   primary_parameter_stores             = {for a,b in var.manifest : a => try(flatten(compact([for index, entry in b : entry.products["cacpm"][terraform.workspace] > 0 ? entry.region_name : "" ]))[0], "")}
   san_list                             = local.san_list
   dns_prefix                           = lookup(var.products["cacpm"].parameters, "dns_prefix", "ldap")
   region_list                          = {for x,y in var.manifest : x => compact([for a,b in y : b.products["cacpm"][terraform.workspace] > 0 ? b.region_name : ""])}
   cloud_dns                            = local.cloud_dns
   cloud_provider                       = "aws"
   cloud_providers                      = local.cloud_providers
   subscription_id                      = var.account_owner["aws"][terraform.workspace]
   az                                   = var.manifest["aws"][0].azs
   tenant_id                            = local.tenant_id
   client_id                            = local.client_id
   client_secret                        = local.client_secret
   aws_storage_account                  = var.aws_storage_account
   internet_control_access              = var.internet_control_access[terraform.workspace]

   providers = {
      aws.route53 = aws.route53
      aws = aws.ireland
   }
}

module "capsm_ireland" {
   source                               = "./modules_aws/capsm"
   module                               = "capsm"
   products                             = var.products
   product_name                         = "capsm"
   instance_type                        = var.products["capsm"].instance["aws"][terraform.workspace]
   account_owner                        = var.account_owner["aws"][terraform.workspace]
   ami_account_owner                    = var.ami_account_owner["aws"][terraform.workspace]
   ami_version                          = "${var.products["capsm"].ami["aws"][terraform.workspace]}-v1.0.0e"
   aws_key_pair_id                      = aws_key_pair.ireland_admin_access.id
   module_version                       = "TBA"
   products_installed                   = local.products_installed["aws"]
   vpc_id                               = local.vpcs["ireland"]
   customer_name                        = var.customer_name
   dns_suffix                           = var.dns_suffix
   termination_protection               = var.termination_protection
   cidr_blocks                          = local.subnet_cidr_blocks
   security_group_ids                   = local.security_group_ids["ireland"]
   first_region_running                 = compact([for index, entry in var.manifest["aws"] : entry.products["capsm"][terraform.workspace] > 0 ? index : ""] )[0]
   number_of_regions                    = length(var.manifest["aws"])
   region_number                        = 0
   my_manifest                          = var.manifest["aws"][0]
   number_servers                       = var.manifest["aws"][0].products["capsm"][terraform.workspace]
   subnet_ids                           = local.subnet_ids["ireland"][var.products["capsm"].subnet]
   health_check_grace_period = 300
   primary_parameter_stores             = {for a,b in var.manifest : a => try(flatten(compact([for index, entry in b : entry.products["capsm"][terraform.workspace] > 0 ? entry.region_name : "" ]))[0], "")}
   san_list                             = local.san_list
   dns_prefix                           = lookup(var.products["capsm"].parameters, "dns_prefix", "ldap")
   region_list                          = {for x,y in var.manifest : x => compact([for a,b in y : b.products["capsm"][terraform.workspace] > 0 ? b.region_name : ""])}
   cloud_dns                            = local.cloud_dns
   cloud_provider                       = "aws"
   cloud_providers                      = local.cloud_providers
   subscription_id                      = var.account_owner["aws"][terraform.workspace]
   az                                   = var.manifest["aws"][0].azs
   tenant_id                            = local.tenant_id
   client_id                            = local.client_id
   client_secret                        = local.client_secret
   aws_storage_account                  = var.aws_storage_account
   internet_control_access              = var.internet_control_access[terraform.workspace]

   providers = {
      aws.route53 = aws.route53
      aws = aws.ireland
   }
}

module "capsml_ireland" {
   source                               = "./modules_aws/capsml"
   module                               = "capsml"
   products                             = var.products
   product_name                         = "capsml"
   instance_type                        = var.products["capsml"].instance["aws"][terraform.workspace]
   account_owner                        = var.account_owner["aws"][terraform.workspace]
   ami_account_owner                    = var.ami_account_owner["aws"][terraform.workspace]
   ami_version                          = "${var.products["capsml"].ami["aws"][terraform.workspace]}-v1.0.0e"
   aws_key_pair_id                      = aws_key_pair.ireland_admin_access.id
   module_version                       = "TBA"
   products_installed                   = local.products_installed["aws"]
   vpc_id                               = local.vpcs["ireland"]
   customer_name                        = var.customer_name
   dns_suffix                           = var.dns_suffix
   termination_protection               = var.termination_protection
   cidr_blocks                          = local.subnet_cidr_blocks
   security_group_ids                   = local.security_group_ids["ireland"]
   first_region_running                 = compact([for index, entry in var.manifest["aws"] : entry.products["capsml"][terraform.workspace] > 0 ? index : ""] )[0]
   number_of_regions                    = length(var.manifest["aws"])
   region_number                        = 0
   my_manifest                          = var.manifest["aws"][0]
   number_servers                       = var.manifest["aws"][0].products["capsml"][terraform.workspace]
   subnet_ids                           = local.subnet_ids["ireland"][var.products["capsml"].subnet]
   health_check_grace_period = 300
   primary_parameter_stores             = {for a,b in var.manifest : a => try(flatten(compact([for index, entry in b : entry.products["capsml"][terraform.workspace] > 0 ? entry.region_name : "" ]))[0], "")}
   san_list                             = local.san_list
   dns_prefix                           = lookup(var.products["capsml"].parameters, "dns_prefix", "ldap")
   region_list                          = {for x,y in var.manifest : x => compact([for a,b in y : b.products["capsml"][terraform.workspace] > 0 ? b.region_name : ""])}
   cloud_dns                            = local.cloud_dns
   cloud_provider                       = "aws"
   cloud_providers                      = local.cloud_providers
   subscription_id                      = var.account_owner["aws"][terraform.workspace]
   az                                   = var.manifest["aws"][0].azs
   tenant_id                            = local.tenant_id
   client_id                            = local.client_id
   client_secret                        = local.client_secret
   aws_storage_account                  = var.aws_storage_account
   internet_control_access              = var.internet_control_access[terraform.workspace]

   providers = {
      aws.route53 = aws.route53
      aws = aws.ireland
   }
}

module "capsmp_ireland" {
   source                               = "./modules_aws/capsmp"
   module                               = "capsmp"
   products                             = var.products
   product_name                         = "capsmp"
   instance_type                        = var.products["capsmp"].instance["aws"][terraform.workspace]
   account_owner                        = var.account_owner["aws"][terraform.workspace]
   ami_account_owner                    = var.ami_account_owner["aws"][terraform.workspace]
   ami_version                          = "${var.products["capsmp"].ami["aws"][terraform.workspace]}-v1.0.0e"
   aws_key_pair_id                      = aws_key_pair.ireland_admin_access.id
   module_version                       = "TBA"
   products_installed                   = local.products_installed["aws"]
   vpc_id                               = local.vpcs["ireland"]
   customer_name                        = var.customer_name
   dns_suffix                           = var.dns_suffix
   termination_protection               = var.termination_protection
   cidr_blocks                          = local.subnet_cidr_blocks
   security_group_ids                   = local.security_group_ids["ireland"]
   first_region_running                 = compact([for index, entry in var.manifest["aws"] : entry.products["capsmp"][terraform.workspace] > 0 ? index : ""] )[0]
   number_of_regions                    = length(var.manifest["aws"])
   region_number                        = 0
   my_manifest                          = var.manifest["aws"][0]
   number_servers                       = var.manifest["aws"][0].products["capsmp"][terraform.workspace]
   subnet_ids                           = local.subnet_ids["ireland"][var.products["capsmp"].subnet]
   health_check_grace_period = 300
   primary_parameter_stores             = {for a,b in var.manifest : a => try(flatten(compact([for index, entry in b : entry.products["capsmp"][terraform.workspace] > 0 ? entry.region_name : "" ]))[0], "")}
   san_list                             = local.san_list
   dns_prefix                           = lookup(var.products["capsmp"].parameters, "dns_prefix", "ldap")
   region_list                          = {for x,y in var.manifest : x => compact([for a,b in y : b.products["capsmp"][terraform.workspace] > 0 ? b.region_name : ""])}
   cloud_dns                            = local.cloud_dns
   cloud_provider                       = "aws"
   cloud_providers                      = local.cloud_providers
   subscription_id                      = var.account_owner["aws"][terraform.workspace]
   az                                   = var.manifest["aws"][0].azs
   tenant_id                            = local.tenant_id
   client_id                            = local.client_id
   client_secret                        = local.client_secret
   aws_storage_account                  = var.aws_storage_account
   internet_control_access              = var.internet_control_access[terraform.workspace]

   providers = {
      aws.route53 = aws.route53
      aws = aws.ireland
   }
}

module "capvwa_ireland" {
   source                               = "./modules_aws/capvwa"
   module                               = "capvwa"
   products                             = var.products
   product_name                         = "capvwa"
   instance_type                        = var.products["capvwa"].instance["aws"][terraform.workspace]
   account_owner                        = var.account_owner["aws"][terraform.workspace]
   ami_account_owner                    = var.ami_account_owner["aws"][terraform.workspace]
   ami_version                          = "${var.products["capvwa"].ami["aws"][terraform.workspace]}-v1.0.0e"
   aws_key_pair_id                      = aws_key_pair.ireland_admin_access.id
   module_version                       = "TBA"
   products_installed                   = local.products_installed["aws"]
   vpc_id                               = local.vpcs["ireland"]
   customer_name                        = var.customer_name
   dns_suffix                           = var.dns_suffix
   termination_protection               = var.termination_protection
   cidr_blocks                          = local.subnet_cidr_blocks
   security_group_ids                   = local.security_group_ids["ireland"]
   first_region_running                 = compact([for index, entry in var.manifest["aws"] : entry.products["capvwa"][terraform.workspace] > 0 ? index : ""] )[0]
   number_of_regions                    = length(var.manifest["aws"])
   region_number                        = 0
   my_manifest                          = var.manifest["aws"][0]
   number_servers                       = var.manifest["aws"][0].products["capvwa"][terraform.workspace]
   subnet_ids                           = local.subnet_ids["ireland"][var.products["capvwa"].subnet]
   health_check_grace_period = 300
   primary_parameter_stores             = {for a,b in var.manifest : a => try(flatten(compact([for index, entry in b : entry.products["capvwa"][terraform.workspace] > 0 ? entry.region_name : "" ]))[0], "")}
   san_list                             = local.san_list
   dns_prefix                           = lookup(var.products["capvwa"].parameters, "dns_prefix", "ldap")
   region_list                          = {for x,y in var.manifest : x => compact([for a,b in y : b.products["capvwa"][terraform.workspace] > 0 ? b.region_name : ""])}
   cloud_dns                            = local.cloud_dns
   cloud_provider                       = "aws"
   cloud_providers                      = local.cloud_providers
   subscription_id                      = var.account_owner["aws"][terraform.workspace]
   az                                   = var.manifest["aws"][0].azs
   tenant_id                            = local.tenant_id
   client_id                            = local.client_id
   client_secret                        = local.client_secret
   aws_storage_account                  = var.aws_storage_account
   internet_control_access              = var.internet_control_access[terraform.workspace]

   providers = {
      aws.route53 = aws.route53
      aws = aws.ireland
   }
}

module "cavault_ireland" {
   source                               = "./modules_aws/cavault"
   module                               = "cavault"
   products                             = var.products
   product_name                         = "cavault"
   instance_type                        = var.products["cavault"].instance["aws"][terraform.workspace]
   account_owner                        = var.account_owner["aws"][terraform.workspace]
   ami_account_owner                    = var.ami_account_owner["aws"][terraform.workspace]
   ami_version                          = "${var.products["cavault"].ami["aws"][terraform.workspace]}-v1.0.0e"
   aws_key_pair_id                      = aws_key_pair.ireland_admin_access.id
   module_version                       = "TBA"
   products_installed                   = local.products_installed["aws"]
   vpc_id                               = local.vpcs["ireland"]
   customer_name                        = var.customer_name
   dns_suffix                           = var.dns_suffix
   termination_protection               = var.termination_protection
   cidr_blocks                          = local.subnet_cidr_blocks
   security_group_ids                   = local.security_group_ids["ireland"]
   first_region_running                 = compact([for index, entry in var.manifest["aws"] : entry.products["cavault"][terraform.workspace] > 0 ? index : ""] )[0]
   number_of_regions                    = length(var.manifest["aws"])
   region_number                        = 0
   my_manifest                          = var.manifest["aws"][0]
   number_servers                       = var.manifest["aws"][0].products["cavault"][terraform.workspace]
   subnet_ids                           = local.subnet_ids["ireland"][var.products["cavault"].subnet]
   health_check_grace_period = 300
   primary_parameter_stores             = {for a,b in var.manifest : a => try(flatten(compact([for index, entry in b : entry.products["cavault"][terraform.workspace] > 0 ? entry.region_name : "" ]))[0], "")}
   san_list                             = local.san_list
   dns_prefix                           = lookup(var.products["cavault"].parameters, "dns_prefix", "ldap")
   region_list                          = {for x,y in var.manifest : x => compact([for a,b in y : b.products["cavault"][terraform.workspace] > 0 ? b.region_name : ""])}
   cloud_dns                            = local.cloud_dns
   cloud_provider                       = "aws"
   cloud_providers                      = local.cloud_providers
   subscription_id                      = var.account_owner["aws"][terraform.workspace]
   az                                   = var.manifest["aws"][0].azs
   tenant_id                            = local.tenant_id
   client_id                            = local.client_id
   client_secret                        = local.client_secret
   aws_storage_account                  = var.aws_storage_account
   internet_control_access              = var.internet_control_access[terraform.workspace]

   providers = {
      aws.route53 = aws.route53
      aws = aws.ireland
   }
}

module "control_ireland" {

   source                               = "./modules_aws/control"
   module                               = "control"
   products                             = var.products
   product_name                         = "control"
   instance_type                        = var.products["control"].instance["aws"][terraform.workspace]
   dns_suffix                           = var.dns_suffix
   ami_version                          = "${var.products["control"].ami["aws"][terraform.workspace]}-v1.0.0e"
   aws_key_pair_id                      = aws_key_pair.ireland_admin_access.id
   region_number                        = 0
   customer_name                        = var.customer_name
   products_installed                   = local.products_installed["aws"]
   my_manifest                          = var.manifest["aws"][0]
   vpc_id                               = local.vpcs["ireland"]
   cloud_dns                            = local.cloud_dns
   cloud_provider                       = "aws"
   cloud_providers                      = local.cloud_providers
   termination_protection               = var.termination_protection
   internet_control_access              = var.internet_control_access[terraform.workspace]
   subnet_ids                           = local.subnet_ids["ireland"][var.products["control"].subnet]
   ami_account_owner                    = var.ami_account_owner["aws"][terraform.workspace]
   cidr_blocks                          = local.subnet_cidr_blocks
   security_group_ids                   = local.security_group_ids["ireland"]
   first_region_running                 = compact([for index, entry in var.manifest["aws"] : entry.products["control"][terraform.workspace] > 0 ? index : ""] )[0]
   tenant_id                            = local.tenant_id
   client_id                            = local.client_id
   client_secret                        = local.client_secret
   cloud_peerings                       = local.cloud_peerings

   providers = {
      aws.route53 = aws.route53
      aws = aws.ireland
   }
}

module "network_ireland" {

   account_owner                        = var.account_owner["aws"][terraform.workspace]
   product_name                         = "network"
   products                             = var.products
   cloud_provider                       = "aws"
   module                               = "network"
   source                               = "./modules_aws/network"
   customer_name                        = var.customer_name
   products_installed                   = local.products_installed["aws"]
   region_number                        = 0
   manifest                             = var.manifest
   regions                              = [for region, entry in var.manifest["aws"] : region]
   other_cloud_regions                  = compact([for name, entry in var.manifest : name != "aws" ? name : ""])
   dns_suffix                           = var.dns_suffix
   dns_delegation                       = var.dns_delegation
   cloud_providers                      = local.cloud_providers
   subnets                              = var.subnets
   vpcs                                 = local.vpcs
   cloud_dns                            = local.cloud_dns
   peer_accepts                         = local.peer_accepts
   peer_connects                        = local.peer_connects
   first_region_running                 = compact([for index, entry in var.manifest["aws"] : entry.products["network"][terraform.workspace] > 0 ? index : ""] )[0]
   deployment_status                    = var.deployment_status
   cloud_peerings                       = local.cloud_peerings
   azure_vpn_connections                = local.azure_vpn_connections

   providers = {
      aws.route53 = aws.route53
      aws = aws.ireland
   }
}

module "pingam_ireland" {
   source                               = "./modules_aws/pingam"
   module                               = "pingam"
   products                             = var.products
   product_name                         = "pingam"
   instance_type                        = var.products["pingam"].instance["aws"][terraform.workspace]
   account_owner                        = var.account_owner["aws"][terraform.workspace]
   ami_account_owner                    = var.ami_account_owner["aws"][terraform.workspace]
   ami_version                          = "${var.products["pingam"].ami["aws"][terraform.workspace]}-v1.0.0e"
   aws_key_pair_id                      = aws_key_pair.ireland_admin_access.id
   module_version                       = "TBA"
   products_installed                   = local.products_installed["aws"]
   vpc_id                               = local.vpcs["ireland"]
   customer_name                        = var.customer_name
   dns_suffix                           = var.dns_suffix
   termination_protection               = var.termination_protection
   cidr_blocks                          = local.subnet_cidr_blocks
   security_group_ids                   = local.security_group_ids["ireland"]
   first_region_running                 = compact([for index, entry in var.manifest["aws"] : entry.products["pingam"][terraform.workspace] > 0 ? index : ""] )[0]
   number_of_regions                    = length(var.manifest["aws"])
   region_number                        = 0
   my_manifest                          = var.manifest["aws"][0]
   number_servers                       = var.manifest["aws"][0].products["pingam"][terraform.workspace]
   subnet_ids                           = local.subnet_ids["ireland"][var.products["pingam"].subnet]
   health_check_grace_period = 300
   primary_parameter_stores             = {for a,b in var.manifest : a => try(flatten(compact([for index, entry in b : entry.products["pingam"][terraform.workspace] > 0 ? entry.region_name : "" ]))[0], "")}
   san_list                             = local.san_list
   dns_prefix                           = lookup(var.products["pingam"].parameters, "dns_prefix", "ldap")
   region_list                          = {for x,y in var.manifest : x => compact([for a,b in y : b.products["pingam"][terraform.workspace] > 0 ? b.region_name : ""])}
   cloud_dns                            = local.cloud_dns
   cloud_provider                       = "aws"
   cloud_providers                      = local.cloud_providers
   subscription_id                      = var.account_owner["aws"][terraform.workspace]
   az                                   = var.manifest["aws"][0].azs
   tenant_id                            = local.tenant_id
   client_id                            = local.client_id
   client_secret                        = local.client_secret
   aws_storage_account                  = var.aws_storage_account

   providers = {
      aws.route53 = aws.route53
      aws = aws.ireland
   }
}

module "pingds_ireland" {
   source                               = "./modules_aws/pingds"
   module                               = "pingds"
   products                             = var.products
   product_name                         = "pingds"
   instance_type                        = var.products["pingds"].instance["aws"][terraform.workspace]
   aws_key_pair_id                      = aws_key_pair.ireland_admin_access.id
   account_owner                        = var.account_owner["aws"][terraform.workspace]
   ami_account_owner                    = var.ami_account_owner["aws"][terraform.workspace]
   ami_version                          = "${var.products["pingds"].ami["aws"][terraform.workspace]}-v1.0.0e"
   module_version                       = "TBA"
   products_installed                   = local.products_installed["aws"]
   vpc_id                               = local.vpcs["ireland"]
   customer_name                        = var.customer_name
   dns_suffix                           = var.dns_suffix
   termination_protection               = var.termination_protection
   cidr_blocks                          = local.subnet_cidr_blocks
   security_group_ids                   = local.security_group_ids["ireland"]
   first_region_running                 = compact([for index, entry in var.manifest["aws"] : entry.products["pingds"][terraform.workspace] > 0 ? index : ""] )[0]
   number_of_regions                    = length(var.manifest["aws"])
   region_number                        = 0
   my_manifest                          = var.manifest["aws"][0]
   number_servers                       = var.manifest["aws"][0].products["pingds"][terraform.workspace]
   subnet_ids                           = local.subnet_ids["ireland"][var.products["pingds"].subnet]
   health_check_grace_period = 300
   primary_parameter_stores             = {for a,b in var.manifest : a => try(flatten(compact([for index, entry in b : entry.products["pingds"][terraform.workspace] > 0 ? entry.region_name : "" ]))[0], "")}
   san_list                             = local.san_list
   dns_prefix                           = lookup(var.products["pingds"].parameters, "dns_prefix", "ldap")
   region_list                          = {for x,y in var.manifest : x => compact([for a,b in y : b.products["pingds"][terraform.workspace] > 0 ? b.region_name : ""])}
   cloud_dns                            = local.cloud_dns
   cloud_provider                       = "aws"
   cloud_providers                      = local.cloud_providers
   subscription_id                      = var.account_owner["aws"][terraform.workspace]
   az                                   = var.manifest["aws"][0].azs
   tenant_id                            = local.tenant_id
   client_id                            = local.client_id
   client_secret                        = local.client_secret
   aws_storage_account                  = var.aws_storage_account

   providers = {
      aws.route53 = aws.route53
      aws = aws.ireland
   }
}

module "pingidm_ireland" {
   source                               = "./modules_aws/pingidm"
   module                               = "pingidm"
   products                             = var.products
   product_name                         = "pingidm"
   instance_type                        = var.products["pingidm"].instance["aws"][terraform.workspace]
   account_owner                        = var.account_owner["aws"][terraform.workspace]
   ami_account_owner                    = var.ami_account_owner["aws"][terraform.workspace]
   ami_version                          = "${var.products["pingidm"].ami["aws"][terraform.workspace]}-v1.0.0e"
   aws_key_pair_id                      = aws_key_pair.ireland_admin_access.id
   module_version                       = "TBA"
   products_installed                   = local.products_installed["aws"]
   vpc_id                               = local.vpcs["ireland"]
   customer_name                        = var.customer_name
   dns_suffix                           = var.dns_suffix
   termination_protection               = var.termination_protection
   cidr_blocks                          = local.subnet_cidr_blocks
   security_group_ids                   = local.security_group_ids["ireland"]
   first_region_running                 = compact([for index, entry in var.manifest["aws"] : entry.products["pingidm"][terraform.workspace] > 0 ? index : ""] )[0]
   number_of_regions                    = length(var.manifest["aws"])
   region_number                        = 0
   my_manifest                          = var.manifest["aws"][0]
   number_servers                       = var.manifest["aws"][0].products["pingidm"][terraform.workspace]
   subnet_ids                           = local.subnet_ids["ireland"][var.products["pingidm"].subnet]
   health_check_grace_period = 300
   primary_parameter_stores             = {for a,b in var.manifest : a => try(flatten(compact([for index, entry in b : entry.products["pingidm"][terraform.workspace] > 0 ? entry.region_name : "" ]))[0], "")}
   san_list                             = local.san_list
   dns_prefix                           = lookup(var.products["pingidm"].parameters, "dns_prefix", "ldap")
   region_list                          = {for x,y in var.manifest : x => compact([for a,b in y : b.products["pingidm"][terraform.workspace] > 0 ? b.region_name : ""])}
   cloud_dns                            = local.cloud_dns
   cloud_provider                       = "aws"
   cloud_providers                      = local.cloud_providers
   subscription_id                      = var.account_owner["aws"][terraform.workspace]
   az                                   = var.manifest["aws"][0].azs
   tenant_id                            = local.tenant_id
   client_id                            = local.client_id
   client_secret                        = local.client_secret
   aws_storage_account                  = var.aws_storage_account

   providers = {
      aws.route53 = aws.route53
      aws = aws.ireland
   }
}

