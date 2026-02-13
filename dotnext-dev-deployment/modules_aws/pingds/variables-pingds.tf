variable "account_owner" {
  type = string
}

variable "ami_version" {
   type = string
}

variable "subscription_id" {
   type = string
}

variable "cloud_provider" {
   type = string
}

variable "cloud_providers" {
   type = list(string)
}

variable "instance_type" {
   type = string
}

variable "module" {
   type = string
}

variable "region_list" {
   type = map(list(string))
}

variable "products" {}

variable "tenant_id" {
   type = string
}  

variable "client_id" {
   type = string
}  

variable "client_secret" {
   type = string
}  

variable "product_name" {
   type = string
}

variable "primary_parameter_stores" {
   type = map(string)
}

variable "number_of_regions" {
   type = number
}

variable "module_version" {
  type = string
}

variable "first_region_running" {
   type = number
}

variable "products_installed" {
   type = map(map(bool))
}

variable "security_group_ids" {
   type = map(string)
}

variable "cidr_blocks" {
   type = map(list(string))
}

variable "my_manifest" {
  type = object({
    region_alias = string
    region_name = string
    enable_vpn = bool
    azs = list (string)
    products = map(map(number))
    network_range = map (string)
  })
}

variable "subnet_ids" {
  type = list(string)
}

variable "region_number" {
   type = number
}

variable "cloud_dns" {}

variable "number_servers" {
   type = number
}

variable "az" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "customer_name" {
  type = string
}

variable "dns_prefix" {
  type = string
}

variable "dns_suffix" {
  type = map(string)
}

variable "aws_key_pair_id" {
  type = string
}

variable "termination_protection" {
  type = bool
}

variable "ami_account_owner" {
  type = string
}

variable "health_check_grace_period" {
   type = number
}

variable "pingds_drives" {
   
  type = list(object({
    awsName  = string
    diskName = string
    volumeName = string
    mountPoint = string
    volumeType = string
    diskSize = number
    iops = number
    throughput = number
    encrypt = bool
    deleteOnT = bool
  }))

  default =  [
    { awsName = "/dev/sdf", diskName = "/dev/nvme1n1", volumeName = "opendj", mountPoint = "/data",
      volumeType = "gp3", iops = 3000, throughput = 125, diskSize = 5, encrypt = true, deleteOnT  = true }
  ]
}

variable "san_list" {
   type = list(string)
}  

variable "aws_storage_account" {
  type = string
}
