resource "aws_instance" "control_server" {
   instance_type = var.instance_type
   ami           = data.aws_ami.control_ami.id
   key_name      = var.aws_key_pair_id

  associate_public_ip_address = true

  subnet_id = element(var.subnet_ids, length(var.subnet_ids)-1)

  user_data = templatefile("${path.module}/scripts/control.sh", {
      CUSTOMER                = var.customer_name
      ENVIRONMENT             = terraform.workspace
      REGION                  = var.my_manifest.region_name
      REGION_ALIAS            = var.my_manifest.region_alias
      BUILD_VERSION           = data.aws_ami.control_ami.name
      TENANT_ID               = var.tenant_id
      CLIENT_ID               = var.client_id
      CLIENT_SECRET           = var.client_secret
      PRODUCT_NAME            = var.product_name
      CLOUD_PROVIDERS         = replace(jsonencode(var.cloud_providers), "\"", "\\\"")
      INTERNAL_DNS_ID         = var.cloud_dns[var.cloud_provider]["internal"].dns_zone_id
      INTERNAL_DNS_NAME       = var.cloud_dns[var.cloud_provider]["internal"].dns_zone_name
      PRODUCT_NAME            = var.product_name
      CLOUD_PROVIDER          = var.cloud_provider
    })

  iam_instance_profile = "${var.product_name}-server"

  disable_api_termination = var.termination_protection

  ebs_optimized = true

  vpc_security_group_ids = concat([var.security_group_ids[basename(abspath(path.module))]], aws_security_group.control[*].id)

  root_block_device {
    encrypted = true
  }

  tags = {
    Name = var.product_name
  }
 
  lifecycle {
     ignore_changes = [ tags, tags_all, ami ]
  }

  depends_on = [ aws_security_group.control ]
}
