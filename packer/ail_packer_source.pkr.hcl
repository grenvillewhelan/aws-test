source "amazon-ebs" "AIL-base" {
  ami_name      = "${var.ami_prefix}-${var.os_base}-arm-base-${var.tag_version}"
  instance_type = "t4g.small"
  region        = var.region
  ami_regions   = var.ami_regions
  profile       = var.profile

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/${var.os_base}-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners = [ "099720109477" ]
  }

  ssh_username = var.ssh_username
  encrypt_boot = true
  iam_instance_profile = "packer"
  tags = {
    "Name" = "${var.ami_prefix}-${var.os_base}-arm-base-${var.tag_version}"
    "ServerType": "base"
    "ImageVersion": "${var.tag_version}"
  }
}

source "amazon-ebs" "AIL-control" {
  ami_name      = "${var.ami_prefix}-${var.os_base}-arm-control-${var.tag_version}"
  instance_type = "t4g.small"
  region        = var.region
  ami_regions   = var.ami_regions
  profile       = var.profile

  source_ami_filter {
    filters = {
      name                = "AIL-${var.os_base}-arm-base-${var.tag_version}"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = [ var.aws_account ]
  }

  ssh_username = var.ssh_username
  encrypt_boot = true
  iam_instance_profile = "packer"

  tags = {
    "Name" = "${var.ami_prefix}-${var.os_base}-arm-control-${var.tag_version}"
    "ServerType": "control"
    "ImageVersion": "{{ .SourceAMITags.ImageVersion }}"
  }
}

source "amazon-ebs" "AIL-pingds" {
  ami_name      = "${var.ami_prefix}-${var.os_base}-arm-pingds-${var.tag_version}"
  instance_type = "t4g.small"
  region        = var.region
  ami_regions   = var.ami_regions
  profile       = var.profile

  source_ami_filter {
    filters = {
      name                = "AIL-${var.os_base}-arm-base-${var.tag_version}"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = [ var.aws_account ]
  }

  ssh_username = var.ssh_username
  encrypt_boot = true
  iam_instance_profile = "packer"

  tags = {
    "Name" = "${var.ami_prefix}-${var.os_base}-arm-pingds-${var.tag_version}"
    "ServerType": "pingdir"
    "ImageVersion": "{{ .SourceAMITags.ImageVersion }}"
  }
}

source "amazon-ebs" "AIL-pingam" {
  ami_name      = "${var.ami_prefix}-${var.os_base}-arm-pingam-${var.tag_version}"
  instance_type = "t4g.small"
  region        = var.region
  ami_regions   = var.ami_regions
  profile       = var.profile

  source_ami_filter {
    filters = {
      name                = "AIL-${var.os_base}-arm-base-${var.tag_version}"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = [ var.aws_account ]
  }

  ssh_username = var.ssh_username
  encrypt_boot = true
  iam_instance_profile = "packer"

  tags = {
    "Name" = "${var.ami_prefix}-${var.os_base}-arm-pingam-${var.tag_version}"
    "ServerType": "pingdir"
    "ImageVersion": "{{ .SourceAMITags.ImageVersion }}"
  }
}

source "amazon-ebs" "AIL-pingidm" {
  ami_name      = "${var.ami_prefix}-${var.os_base}-arm-pingidm-${var.tag_version}"
  instance_type = "t4g.small"
  region        = var.region
  ami_regions   = var.ami_regions
  profile       = var.profile

  source_ami_filter {
    filters = {
      name                = "AIL-${var.os_base}-arm-base-${var.tag_version}"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = [ var.aws_account ]
  }

  ssh_username = var.ssh_username
  encrypt_boot = true
  iam_instance_profile = "packer"

  tags = {
    "Name" = "${var.ami_prefix}-${var.os_base}-arm-pingidm-${var.tag_version}"
    "ServerType": "pingdir"
    "ImageVersion": "{{ .SourceAMITags.ImageVersion }}"
  }
}

source "amazon-ebs" "AIL-cyberark" {
  ami_name      = "${var.ami_prefix}-${var.os_base_win}-cyberark-${var.tag_version}"
  instance_type = "t3.small" # x86_64 architecture
  region        = var.region
  profile       = var.profile

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = 1
  }

  source_ami_filter {
    filters = { 
      name                = "Windows_Server-2022-English-Full-Base-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
      architecture        = "x86_64" # Must match t3.small
    } 
    most_recent = true    
    owners      = ["801119661308"] # Amazon Windows
  } 

  communicator   = "winrm"
  winrm_username = "Administrator"
  winrm_password = "PackerPassword123!" # Matches the script above
  winrm_use_ssl  = false
  winrm_insecure = true 
  winrm_port     = 5985

user_data = <<EOF
<powershell>
# 1. Set the Administrator password (must match winrm_password in HCL)
$admin = [adsi]"WinNT://localhost/Administrator,user"
$admin.SetPassword("PackerPassword123!")
$admin.SetInfo()

# 2. Configure WinRM for HTTP (5985)
# This allows Packer to connect and run your provisioners
winrm quickconfig -q
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'

# 3. Open Firewall for WinRM (5985) and RDP (3389)
# Opening 3389 here saves you a massive headache in Terraform later
netsh advfirewall firewall add rule name="WinRM-HTTP" dir=in action=allow protocol=TCP localport=5985
netsh advfirewall firewall add rule name="Allow-RDP" dir=in action=allow protocol=TCP localport=3389

# 4. Restart service to apply
Restart-Service WinRM
</powershell>
EOF

  iam_instance_profile = "packer"
  
  tags = {
    "Name"         = "${var.ami_prefix}-${var.os_base_win}-cyberark-${var.tag_version}"
    "ServerType"   = "cyberark" 
    "ImageVersion" = "${var.tag_version}"
  }
}

