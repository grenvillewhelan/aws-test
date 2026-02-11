variable "ami_prefix" {
   type = string
   default = "AIL"
}

variable "location" {
  type    = string
  default = "none"
}

variable "customer_name" {
   type = string
}

variable "environment_name" {
   type = string
}

variable "dns_suffix" {
   type = string
}

variable "aws_access_key_id" {
   type = string
}

variable "aws_secret_access_key" {
   type = string
}

variable "subscription_id" {
   type = string
   default = "none"
}

variable "ssh_username" {
   type = string
   default = "ubuntu"
}

variable "tenant_id" {
   type = string
   default = "none"
}

variable "client_id" {
   type = string
   default = "none"
}

variable "client_secret" {
   type = string
   default = "none"
}

variable "region" {
  type    = string
  default = "none"
}

variable "software_region" {
  type    = string
  default = "eu-west-1"
}

variable "ami_regions" {
  type    = list(string)
  default = []
}

variable "tag_version" {
  type    = string
  default = "unknown"
}

variable "profile" {
  type    = string
  default = "packer"
}

variable "os_base" {
   type = string
   default = "none"
}

variable "os_redhat_base" {
   type = string
   default = "none"
}

variable "os_base_win" {
   type = string
   default = "none"
}

variable "aws_account" {
  type = string
  default = "none"
}

variable "resource_group" {
   type = string
   default = "none"
}

variable "harbian_version" {
  type = string
}

variable "account_key" {
   type = string
   default = "none"
}

variable "pingfed_version" {
  type = string
}

variable "pingdir_version" {
   type = string
}

variable "pingds_version" {
   type = string
}

variable "pingidm_version" {
   type = string
}

variable "pingam_version" {
   type = string
}

variable "aws_storage_account" {
  type = string
  default = "dotnext-software"
}
