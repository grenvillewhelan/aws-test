resource "aws_ssm_parameter" "binary_backup_time" {
   name  = join("/", ["", var.customer_name, terraform.workspace, "pingidm", var.products[var.product_name].cluster, "binary_backup_time"])

   value = "02:00"
   type  = "String"

   lifecycle {
      ignore_changes = [ value ]
   }
}

resource "aws_ssm_parameter" "pingidm_root_password" {
   name  = join("/", ["", var.customer_name, terraform.workspace, "pingidm", var.products[var.product_name].cluster, "pingidm_root_password"])

//   value = random_password.pingidm_root_password.result
   value = local.pingidm_root_password
   type  = "SecureString"

   lifecycle {
      ignore_changes = [ value ]
   }
}

resource "aws_ssm_parameter" "pingidm_replication_admin_password" {
   name  = join("/", ["", var.customer_name, terraform.workspace, "pingidm", var.products[var.product_name].cluster, "pingidm_replication_admin_password"])
//   value = random_password.pingidm_replication_admin_password.result
   value = local.pingidm_replication_admin_password

   type  = "SecureString"

   lifecycle {
      ignore_changes = [ value ]
   }
}

resource "aws_ssm_parameter" "pingidm_pingfed_oauth_client_username" {
   name  = join("/", ["", var.customer_name, terraform.workspace, "pingidm", var.products[var.product_name].cluster, "pingidm_pingfed_oauth_client_username"])

   value = local.pingidm_pingfed_oauth_client_username

   type  = "String"

   lifecycle {
      ignore_changes = [ value ]
   }
}

resource "aws_ssm_parameter" "pingidm_pingfed_oauth_client_password" {
   name  = join("/", ["", var.customer_name, terraform.workspace, "pingidm", var.products[var.product_name].cluster, "pingidm_pingfed_oauth_client_password"])
   value = random_password.pingidm_pingfed_oauth_client_password.result
   type  = "SecureString"

   lifecycle {
      ignore_changes = [ value ]
   }
}

resource "aws_ssm_parameter" "pingidm_pfxpassphrase" {
   name  = join("/", ["", var.customer_name, terraform.workspace, "pingidm", var.products[var.product_name].cluster, "pingidm_pfxpassphrase"])

   value = local.pingidm_pfxpassphrase
   type  = "SecureString"

   lifecycle {
      ignore_changes = [ value ]
   }
}

resource "random_password" "pingidm_root_password" {
   length           = 16
   min_lower        = 1
   min_upper        = 1
   min_numeric      = 1
   min_special      = 1
   special          = true
   override_special = "%@()_=+[]~{}:?"
}

resource "random_password" "pingidm_replication_admin_password" {
   length           = 16
   min_lower        = 1
   min_upper        = 1
   min_numeric      = 1
   min_special      = 1
   special          = true
   override_special = "%@()_=+[]~{}:?"
}

resource "random_password" "pingidm_pingfed_oauth_client_password" {
   length           = 16
   min_lower        = 1
   min_upper        = 1
   min_numeric      = 1
   min_special      = 1
   special          = true
   override_special = "%@()_=+[]~{}:?"
}

locals {

   pingidm_root_password = "S@usage5liPPer5!"
   pingidm_replication_admin_password = "S@gs7gj5P@PPer5!"
   pingidm_pfxpassphrase = "5lipper5"
   pingidm_pingfed_oauth_client_username = "pfoauth"
}

