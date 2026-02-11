resource "aws_ssm_parameter" "binary_backup_time" {
   name  = join("/", ["", var.customer_name, terraform.workspace, "pingam", var.products[var.product_name].cluster, "binary_backup_time"])

   value = "02:00"
   type  = "String"

   lifecycle {
      ignore_changes = [ value ]
   }
}

resource "aws_ssm_parameter" "pingam_root_password" {
   name  = join("/", ["", var.customer_name, terraform.workspace, "pingam", var.products[var.product_name].cluster, "pingam_root_password"])

//   value = random_password.pingam_root_password.result
   value = local.pingam_root_password
   type  = "SecureString"

   lifecycle {
      ignore_changes = [ value ]
   }
}

resource "aws_ssm_parameter" "pingam_replication_admin_password" {
   name  = join("/", ["", var.customer_name, terraform.workspace, "pingam", var.products[var.product_name].cluster, "pingam_replication_admin_password"])
//   value = random_password.pingam_replication_admin_password.result
   value = local.pingam_replication_admin_password

   type  = "SecureString"

   lifecycle {
      ignore_changes = [ value ]
   }
}

resource "aws_ssm_parameter" "pingam_pingfed_oauth_client_username" {
   name  = join("/", ["", var.customer_name, terraform.workspace, "pingam", var.products[var.product_name].cluster, "pingam_pingfed_oauth_client_username"])

   value = local.pingam_pingfed_oauth_client_username

   type  = "String"

   lifecycle {
      ignore_changes = [ value ]
   }
}

resource "aws_ssm_parameter" "pingam_pingfed_oauth_client_password" {
   name  = join("/", ["", var.customer_name, terraform.workspace, "pingam", var.products[var.product_name].cluster, "pingam_pingfed_oauth_client_password"])
   value = random_password.pingam_pingfed_oauth_client_password.result
   type  = "SecureString"

   lifecycle {
      ignore_changes = [ value ]
   }
}

resource "aws_ssm_parameter" "pingam_pfxpassphrase" {
   name  = join("/", ["", var.customer_name, terraform.workspace, "pingam", var.products[var.product_name].cluster, "pingam_pfxpassphrase"])

   value = local.pingam_pfxpassphrase
   type  = "SecureString"

   lifecycle {
      ignore_changes = [ value ]
   }
}

resource "random_password" "pingam_root_password" {
   length           = 16
   min_lower        = 1
   min_upper        = 1
   min_numeric      = 1
   min_special      = 1
   special          = true
   override_special = "%@()_=+[]~{}:?"
}

resource "random_password" "pingam_replication_admin_password" {
   length           = 16
   min_lower        = 1
   min_upper        = 1
   min_numeric      = 1
   min_special      = 1
   special          = true
   override_special = "%@()_=+[]~{}:?"
}

resource "random_password" "pingam_pingfed_oauth_client_password" {
   length           = 16
   min_lower        = 1
   min_upper        = 1
   min_numeric      = 1
   min_special      = 1
   special          = true
   override_special = "%@()_=+[]~{}:?"
}

locals {

   pingam_root_password = "S@usage5liPPer5!"
   pingam_replication_admin_password = "S@gs7gj5P@PPer5!"
   pingam_pfxpassphrase = "5lipper5"
   pingam_pingfed_oauth_client_username = "pfoauth"
}

