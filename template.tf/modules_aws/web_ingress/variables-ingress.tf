variable "account_owner" {
  type = string
}

variable "module" {
   type = string
}

variable "product_name" {
   type = string
}

variable "cloud_dns" {}

variable "security_group_ids" {
   type = map(string)
}

variable "cidr_blocks" {
   type = map(list(string))
}

variable "first_region_running" {
   type = number
}

variable "lb_type" {
   type = string
}

variable "products_installed" {
   type = map(map(bool))
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

variable "vpc_id" {
  type = string
}

variable "customer_name" {
  type = string
}

variable "dns_suffix" {
  type = map(string)
}

variable "aws_key_pair_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "https_customer_certificate" {
  type    = bool
}

variable "ingress_logs_enabled" {
   type = bool
   default = true
}

variable "region_number" {
   type = number
}

variable "elb_account_id" {
   type = string
}

variable "san_list" {
   type = list(string)
}

variable "target_group_arns" {
   type = map(map(string))
}

variable "products" {}

