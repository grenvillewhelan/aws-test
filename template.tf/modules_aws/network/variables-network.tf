variable "customer_name" {
  type = string
}

variable "cloud_peerings" {
   type = map(map(list(string)))
}

variable "cloud_providers" {
   type = list(string)
}

variable "cloud_provider" {
   type = string
}

variable "products" {}

variable "module" {
   type = string
}

variable "product_name" {
   type = string
}

variable "deployment_status" {
   type = string
}

variable "account_owner" {
   type = string
}

variable "first_region_running" {
   type = number
}

variable "peer_accepts" {
   type = map(map(string))
}

variable "peer_connects" {
   type = map(map(string))
}

variable "regions" {
   type = list(number)
}

variable "other_cloud_regions" {
   type = list(string)
}

variable "products_installed" {
   type = map(map(bool))
}

variable "manifest" {
  type = map(list(object({
    region_alias = string
    region_name = string
    enable_vpn = bool
    azs = list (string)
    products = map(map(number))
    network_range = map (string)
  })))
}

variable "region_number" {
   type = number
}

variable "vpcs" {
   type = map(string)
}

variable "dns_suffix" {
  type = map(string)
}

variable "cloud_dns" {}

variable "nat_number_secondary_ips" {
  type = number
  default = 0
  description = "Now many additional IP addressed to bind to each NAT gateway to provide increased throughput"
} 

variable "subnets" {
   type = list(object({
      subnet_name = string
      newbits     = number
      netnum      = number
   }))
}

variable "cloud_asns" {
   type = map(number)

   default = {
      "aws"   = 64512
//      "azure" = 65515
      "azure" = 65510
   }
}

variable "vpn_bgp_base_cidr" {
   type = string
   default = "169.254.21.0"
}

variable "azure_vpn_connections" {}
