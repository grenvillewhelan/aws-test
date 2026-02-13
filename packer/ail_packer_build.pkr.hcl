build {
  name = "AIL-${var.os_base}-base"
  sources = [
    "source.amazon-ebs.AIL-base",
  ]

  provisioner "shell" {
    inline = [
      "sudo mkdir -p /opt/AIL/install",
      "sudo mkdir -p /opt/AIL/tools",
      "sudo chown -R ${var.ssh_username} /opt/AIL"
    ]
  }

  provisioner "file" {
    sources = [
      "scripts/install-ail_base.sh",
      "files/ail_base.sh"
    ]
    destination = "/opt/AIL/install/"
  }

  provisioner "file" {
    sources = [
      "files/utils.sh"
    ]
    destination = "/opt/AIL/tools/"
  }

  provisioner "shell" {
    expect_disconnect = true
    inline = [
      "sudo bash /opt/AIL/install/install-ail_base.sh aws ${var.region} ${var.client_id} ${var.client_secret} ${var.tenant_id} ${var.aws_access_key_id} ${var.aws_secret_access_key}",
      "sudo chmod a+x /opt/AIL/tools/*.sh"
    ]
  }
}

build {
  name = "AIL-${var.os_base}-control"
  sources = [ "source.amazon-ebs.AIL-control" ]

  provisioner "shell" {
    inline = [
      "sudo mkdir -p /opt/ansible/files",
      "sudo chown -R ${var.ssh_username} /opt/ansible"
    ]
  }

  provisioner "file" {
    sources = [
      "scripts/install-control.sh",
      "files/control/scripts/control.sh"
    ]
    destination = "/opt/AIL/install/"
  }

   provisioner "file" {
      sources = [
         "files/control/inventory.yml",
         "files/control/bootstrap_mgmt.yml"
      ]
      destination = "/opt/ansible/files/"
   }


  provisioner "shell" {
    inline = [
      "sudo bash /opt/AIL/install/install-control.sh ${var.region}",
      "sudo chmod a+x /opt/AIL/tools/*.sh"
    ]
  }
}

build {
  name = "AIL-${var.os_redhat_base}-capsm"
  sources = [ "source.amazon-ebs.AIL-capsm" ]

  provisioner "shell" {
    inline = [
      "sudo mkdir -p /opt/AIL/install",
      "sudo mkdir -p /opt/AIL/tools",
      "sudo chown -R ${var.ssh_username} /opt/AIL"
    ]
  }

  provisioner "file" {
    sources = [ 
      "scripts/install-redhat_ail_base.sh",
      "files/ail_base.sh"
    ] 
    destination = "/opt/AIL/install/"
  }   
   
  provisioner "file" {
    sources = [ 
      "files/utils.sh"
    ]    
    destination = "/opt/AIL/tools/"
  }   
   
  provisioner "shell" {
    expect_disconnect = true
    inline = [
      "sudo bash /opt/AIL/install/install-redhat_ail_base.sh aws ${var.region} ${var.client_id} ${var.client_secret} ${var.tenant_id} ${var.aws_access_key_id} ${var.aws_secret_access_key}",
      "sudo chmod a+x /opt/AIL/tools/*.sh"
    ]
  }
}

build {
  name = "AIL-${var.os_base}-pingds"
  sources = [ "source.amazon-ebs.AIL-pingds" ]

   provisioner "file" {
      sources = [
         "scripts/install-pingds.sh",
         "scripts/create-volumes.sh",
         "files/pingds/scripts/pingds.sh"
      ]

      destination = "/opt/AIL/install/"
   }

   provisioner "shell" {
      inline = [
         "sudo bash /opt/AIL/install/install-pingds.sh ${var.pingds_version} ${var.aws_storage_account} ${var.software_region}",
         "sudo chmod a+x /opt/AIL/tools/*.sh"
      ]
   }
}

build {
  name = "AIL-${var.os_base}-pingam"
  sources = [ "source.amazon-ebs.AIL-pingam" ]

   provisioner "file" {
      sources = [
         "scripts/install-pingam.sh",
         "files/pingam/scripts/pingam.sh"
      ]

      destination = "/opt/AIL/install/"
   }

   provisioner "file" {
      sources = [
         "files/pingam/scripts/pingam-tools.sh"
      ]
      destination = "/opt/AIL/tools/"
   }

   provisioner "shell" {
      inline = [
         "sudo bash /opt/AIL/install/install-pingam.sh ${var.pingam_version} ${var.aws_storage_account} ${var.software_region}",
         "sudo chmod a+x /opt/AIL/tools/*.sh"
      ]
   }
}

build {
  name = "AIL-${var.os_base}-pingidm"
  sources = [ "source.amazon-ebs.AIL-pingidm" ]

  provisioner "file" {
     sources = [
        "scripts/install-pingidm.sh",
        "files/pingidm/scripts/pingidm.sh"
     ]

     destination = "/opt/AIL/install/"
  }

   provisioner "file" {
      sources = [
         "files/pingidm/scripts/pingidm-tools.sh"
      ]
      destination = "/opt/AIL/tools/"
   }

   provisioner "shell" {
      inline = [
         "sudo bash /opt/AIL/install/install-pingidm.sh ${var.pingidm_version} ${var.aws_storage_account} ${var.software_region}",
         "sudo chmod a+x /opt/AIL/tools/*.sh"
      ]
   }
}

build {
  name = "AIL-${var.os_base}-cyberark"
  sources = [ "source.amazon-ebs.AIL-cyberark" ]

  provisioner "powershell" {
    script = "./scripts/install-cyberark.ps1"
  }
}
