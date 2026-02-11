dns_suffix  = {
   "aws"   = "dotnext.accessidentifiedcloud.com"
}

dns_delegation = {
  "aws"    = "N0633201T77TLFPVW9M0"
}

account_owner = {

   "aws" = {
      "dev"              = "815931740430"
      "prod"             = "762233743855"
   }
}

ami_account_owner = {

   "aws" = {
      "dev"              = "815931740430"
      "prod"             = "762233743855"
   }
}

aws_storage_account = "dotnext-software"

manifest = {

   "azure" = []

   "aws" = [
      {
         region_name     = "eu-west-1"
         region_alias    = "ireland"
         enable_vpn      = true
   
         azs             = [ "a", "b", "c" ]
   
         products = {
                        "network"           = { dev = 1, prod = 1}
                        "web_ingress"       = { dev = 0, prod = 0}
                        "control"           = { dev = 1, prod = 1}
                        "cavault"           = { dev = 1, prod = 1}
                        "capvwa"            = { dev = 1, prod = 1}
                        "cacpm"             = { dev = 1, prod = 1}
                        "capsm"             = { dev = 1, prod = 1}
                        "capsml"            = { dev = 1, prod = 1}
                        "capsmp"            = { dev = 1, prod = 1}
                        "pingds"            = { dev = 1, prod = 1}
                        "pingam"            = { dev = 1, prod = 1}
                        "pingidm"           = { dev = 1, prod = 1}
                     }
   
         network_range   = { "dev"  = "10.10.10.0/23",
                             "prod" = "20.20.20.0/23" }
      }
   ]
}


subnets = [
             { subnet_name = "internet",    newbits = 5, netnum = 0,  nat_gw = false },
             { subnet_name = "admin",       newbits = 5, netnum = 3,  nat_gw = true  },
             { subnet_name = "application", newbits = 5, netnum = 6,  nat_gw = true  },
             { subnet_name = "management",  newbits = 5, netnum = 9,  nat_gw = true  },
             { subnet_name = "data",        newbits = 4, netnum = 6,  nat_gw = true  },
             { subnet_name = "wan",         newbits = 4, netnum = 10, nat_gw = false }
          ]

internet_control_access = {
   "dev"  = [
             "82.9.79.207/32",           // Gren home
             "197.87.7.107/32",          // Andre home
             "102.66.192.81/32"          // KG home
            ] 
   "prod" = ["82.9.79.207/32"]
}

products = {
    "network" = {
        module          = "network"
        cluster         = ""
        subnet          = "internet"
        ami             = {}
        instance        = {}
        requires        = ""
        parameters      = {}
     }

     "web_ingress" = {
        module          = "web_ingress"
        cluster         = ""
        subnet          = "internet"
        ami             = {}
        instance        = {}
        requires        = "network"
        parameters      = {
                             "log"                  = false
                             "backup_prefix"        = "web-ingress-logs"
                          }
     }

     "control" = {
        module          = "control"
        cluster         = ""
        subnet          = "management"
        ami             = {
                             "aws" = { 
                                "dev"  = "AIL-ubuntu-jammy-22.04-arm64-server-arm-control"
                                "prod" = "AIL-ubuntu-jammy-22.04-arm64-server-arm-control"
                             }
                          }
        instance        = {
                             "aws" = {
                                "dev"  = "t4g.micro"
                                "prod" = "t4g.micro"
                             }
                          }
        requires        = "network"
        parameters      = {}
     }

     "cavault" = {
        module          = "cavault"
        cluster         = ""
        subnet          = "internet"
        ami             = {
                             "aws" = { 
                                "dev"  = "AIL-Windows_Server-2022-English-Core-Base-cyberark"
                                "prod" = "AIL-Windows_Server-2022-English-Core-Base-cyberark"
                             }
                          }
        instance        = {
                             "aws" = {
                                "dev"  = "t3.medium"
                                "prod" = "t3.medium"
                             }
                          }
        requires        = "network"
        parameters      = {}
     }

     "capvwa" = {
        module          = "capvwa"
        cluster         = ""
        subnet          = "internet"
        ami             = {
                             "aws" = { 
                                "dev"  = "AIL-Windows_Server-2022-English-Core-Base-cyberark"
                                "prod" = "AIL-Windows_Server-2022-English-Core-Base-cyberark"
                             }
                          }
        instance        = {
                             "aws" = {
                                "dev"  = "t3.medium"
                                "prod" = "t3.medium"
                             }
                          }
        requires        = "network"
        parameters      = {}
     }

     "cacpm" = {
        module          = "cacpm"
        cluster         = ""
        subnet          = "internet"
        ami             = {
                             "aws" = { 
                                "dev"  = "AIL-Windows_Server-2022-English-Core-Base-cyberark"
                                "prod" = "AIL-Windows_Server-2022-English-Core-Base-cyberark"
                             }
                          }
        instance        = {
                             "aws" = {
                                "dev"  = "t3.medium"
                                "prod" = "t3.medium"
                             }
                          }
        requires        = "network"
        parameters      = {}
     }

     "capsm" = {
        module          = "capsm"
        cluster         = ""
        subnet          = "internet"
        ami             = {
                             "aws" = { 
                                "dev"  = "AIL-Windows_Server-2022-English-Core-Base-cyberark"
                                "prod" = "AIL-Windows_Server-2022-English-Core-Base-cyberark"
                             }
                          }
        instance        = {
                             "aws" = {
                                "dev"  = "t3.medium"
                                "prod" = "t3.medium"
                             }
                          }
        requires        = "network"
        parameters      = {}
     }

     "capsml" = {
        module          = "capsml"
        cluster         = ""
        subnet          = "internet"
        ami             = {
                             "aws" = { 
                                "dev"  = "AIL-RHEL-9.3.0_HVM-20240229-arm64-arm-capsm"
                                "prod" = "AIL-RHEL-9.3.0_HVM-20240229-arm64-arm-capsm"
                             }
                          }
        instance        = {
                             "aws" = {
                                "dev"  = "t4g.micro"
                                "prod" = "t4g.micro"
                             }
                          }
        requires        = "network"
        parameters      = {}
     }

     "capsmp" = {
        module          = "capsmp"
        cluster         = ""
        subnet          = "internet"
        ami             = {
                             "aws" = { 
                                "dev"  = "AIL-Windows_Server-2022-English-Core-Base-cyberark"
                                "prod" = "AIL-Windows_Server-2022-English-Core-Base-cyberark"
                             }
                          }
        instance        = {
                             "aws" = {
                                "dev"  = "t3.medium"
                                "prod" = "t3.medium"
                             }
                          }
        requires        = "network"
        parameters      = {}
     }

     "pingds" = {
        module          = "pingds"
        cluster         = "pingds"
        subnet          = "data"
        ami             = {
                             "aws" = { 
                                "dev"  = "AIL-ubuntu-jammy-22.04-arm64-server-arm-pingds"
                                "prod" = "AIL-ubuntu-jammy-22.04-arm64-server-arm-pingds"
                             }
                          }
        instance        = {
                             "aws" = {
                                "dev"  = "t4g.micro"
                                "prod" = "t4g.micro"
                             }
                          }
        requires        = "network"
        parameters      = {  "backup_prefix"            = "pingds"
                             "dns_prefix"               = "ldap",
                             "web_ingress"              = false
                             "pingfed_cluster"          = ""
                             "pingds_log_retention"    = 7
                             "pingds_ldif_backup_time" = "03:00"
                             "pingds_backup_time"      = "02:00"
                             "host_name"                = "ldap",
                             "frontend_port"            = 8443,
                             "backend_port"             = 8443,
                             "healthcheck_path"         = "/available-state",
                             "healthcheck_interval"     = 10,
                             "healthcheck_timeout"      = 10,
                             "unhealthy_threshold"      = 3
                          }
     }

     "pingam" = {
        module          = "pingam"
        cluster         = "pingam"
        subnet          = "data"
        ami             = {
                             "aws" = { 
                                "dev"  = "AIL-ubuntu-jammy-22.04-arm64-server-arm-pingam"
                                "prod" = "AIL-ubuntu-jammy-22.04-arm64-server-arm-pingam"
                             }
                          }
        instance        = {
                             "aws" = {
                                "dev"  = "t4g.micro"
                                "prod" = "t4g.micro"
                             }
                          }
        requires        = "network"
        parameters      = {  "backup_prefix"            = "pingam"
                             "dns_prefix"               = "ldap",
                             "web_ingress"              = false
                             "pingfed_cluster"          = ""
                             "pingds_log_retention"    = 7
                             "pingds_ldif_backup_time" = "03:00"
                             "pingds_backup_time"      = "02:00"
                             "host_name"                = "ldap",
                             "frontend_port"            = 8443,
                             "backend_port"             = 8443,
                             "healthcheck_path"         = "/available-state",
                             "healthcheck_interval"     = 10,
                             "healthcheck_timeout"      = 10,
                             "unhealthy_threshold"      = 3
                          }
     }

     "pingidm" = {
        module          = "pingidm"
        cluster         = "pingidm"
        subnet          = "data"
        ami             = {
                             "aws" = { 
                                "dev"  = "AIL-ubuntu-jammy-22.04-arm64-server-arm-pingidm"
                                "prod" = "AIL-ubuntu-jammy-22.04-arm64-server-arm-pingidm"
                             }
                          }
        instance        = {
                             "aws" = {
                                "dev"  = "t4g.micro"
                                "prod" = "t4g.micro"
                             }
                          }
        requires        = "network"
        parameters      = {  "backup_prefix"            = "pingidm"
                             "dns_prefix"               = "ldap",
                             "web_ingress"              = false
                             "pingfed_cluster"          = ""
                             "pingds_log_retention"    = 7
                             "pingds_ldif_backup_time" = "03:00"
                             "pingds_backup_time"      = "02:00"
                             "host_name"                = "ldap",
                             "frontend_port"            = 8443,
                             "backend_port"             = 8443,
                             "healthcheck_path"         = "/available-state",
                             "healthcheck_interval"     = 10,
                             "healthcheck_timeout"      = 10,
                             "unhealthy_threshold"      = 3
                          }
     }

}

test_mode                               = true
https_customer_certificate              = false
route53_provider                        = "gwhelan_dev"
build_version                           = "TBA"
termination_protection                  = true

