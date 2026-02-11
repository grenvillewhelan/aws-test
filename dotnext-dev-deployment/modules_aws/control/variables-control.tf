variable "vpc_id" {
  type = string
}

variable "ami_version" {
   type = string
}

variable "cloud_peerings" {
   type = map(map(list(string)))
}

variable "dns_suffix" {
   type = map(string)
}

variable "instance_type" {
   type = string
}

variable "module" {
   type = string
}

variable "products" {}

variable "product_name" {
   type = string
}

variable "first_region_running" {
   type = number
}

variable "cloud_provider" {
   type = string
}

variable "cloud_providers" {
   type = list(string)
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

variable "region_number" {
   type = number
}

variable "cloud_dns" {}

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

variable "aws_key_pair_id" {
   type = string
}

variable "ami_account_owner" {
   type = string
}

variable "customer_name" {
   type = string
}

variable "termination_protection" {
   type = bool
}

variable "internet_control_access" {
   type = list(string)
}

variable "tenant_id" {
   type = string
}
   
variable "client_id" {
   type = string
}
   
variable "client_secret" {
   type = string
}
