resource "aws_instance" "pingds_server" {
   count         = var.number_servers
   subnet_id     = element(var.subnet_ids, count.index%length(var.subnet_ids))
   instance_type = var.instance_type
   key_name      = var.aws_key_pair_id
   availability_zone = join("", [var.my_manifest.region_name, var.az[count.index % length(var.az)]])

  iam_instance_profile =   "${local.hyphenated_name}-server"

  ami = data.aws_ami.pingds_ami.id

  user_data = templatefile("${path.module}/scripts/pingds.sh", {
        CUSTOMER                               = var.customer_name
        DRIVES                                 = jsonencode (var.pingds_drives)
        ENVIRONMENT                            = terraform.workspace
        REGION                                 = var.my_manifest.region_name
        REGION_ALIAS                           = var.my_manifest.region_alias
        BUILD_VERSION                          = data.aws_ami.pingds_ami.name
        MODULE_VERSION                         = var.module_version
        PRODUCT                                = "pingds"
        SERVER_INSTANCE                        = count.index + 1
        PRIMARY_PARAMETER_STORES               = replace(jsonencode(var.primary_parameter_stores), "\"", "\\\"")
        DNS_SUFFIX                             = var.dns_suffix["aws"]
        CLUSTER                                = var.products[var.product_name].cluster
        PRODUCT_NAME                           = var.product_name
        REGION_LIST                            = replace(jsonencode(var.region_list), "\"", "\\\"")
        CLOUD_PROVIDER                         = var.cloud_provider
        CLOUD_PROVIDERS                        = replace(jsonencode(var.cloud_providers), "\"", "\\\"")
        CLOUD_DNS                              = replace(jsonencode(var.cloud_dns), "\"", "\\\"")
        SUBSCRIPTION_ID                        = var.subscription_id
      })

  disable_api_termination = var.termination_protection

  ebs_optimized = true

  vpc_security_group_ids = concat([var.security_group_ids["${var.product_name}"]], aws_security_group.pingds[*].id)

  tags = {
    Name        = join ("",["${var.product_name}-",count.index])
    ServerType  = "PingDS"
    Status      = "unreplicated"
    Environment = terraform.workspace
  }

  depends_on = [
                  aws_iam_policy_attachment.pingds_server
  ]

  lifecycle {
    ignore_changes = [ tags, tags_all, ami, user_data ]
  }
}

resource "aws_ebs_volume" "pingds_ebs_volumes" {
  count = length(var.pingds_drives) * var.number_servers
        
  availability_zone = join("", [var.my_manifest.region_name, var.az[(count.index % var.number_servers) % length(var.az)]])
        
  size              = var.pingds_drives[floor(count.index/var.number_servers)].diskSize
  type              = var.pingds_drives[floor(count.index/var.number_servers)].volumeType
  iops              = var.pingds_drives[floor(count.index/var.number_servers)].iops
  throughput        = var.pingds_drives[floor(count.index/var.number_servers)].throughput
  encrypted         = var.pingds_drives[floor(count.index/var.number_servers)].encrypt

  tags = {
    Name = "${var.pingds_drives[floor(count.index/var.number_servers)].awsName} -> ${var.pingds_drives[floor(count.index/var.number_servers)].diskName}"    
  }     
}       
        
resource "aws_volume_attachment" "pingds_ebs_attachment" {
  count = length(var.pingds_drives) * var.number_servers
  device_name = var.pingds_drives[floor(count.index/var.number_servers)].awsName
  volume_id   = aws_ebs_volume.pingds_ebs_volumes[count.index].id
  instance_id = aws_instance.pingds_server[count.index % var.number_servers].id
}
