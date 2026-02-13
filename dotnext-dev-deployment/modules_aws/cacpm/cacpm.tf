resource "aws_instance" "cacpm_server" {
  count         = var.number_servers
  subnet_id     = element(var.subnet_ids, count.index%length(var.subnet_ids))
  instance_type = var.instance_type
  key_name      = var.aws_key_pair_id
  availability_zone = join("", [var.my_manifest.region_name, var.az[count.index % length(var.az)]])
  ami           = data.aws_ami.cacpm_ami.id
  associate_public_ip_address = true
  
user_data = <<EOF
<powershell>
# 1. Kill the Firewall immediately
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# 2. Enable RDP and disable NLA
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 0

# 3. Force RDP service restart
Restart-Service TermService -Force
</powershell>
EOF

  vpc_security_group_ids = concat([var.security_group_ids["${var.product_name}"]], aws_security_group.cacpm[*].id)


  tags = {
    Name        = join ("",["${var.product_name}-",count.index])
    ServerType  = "CyberarmCPM"
    Environment = terraform.workspace
  }
}

//output "admin_passwords" {
//  value = [
//    for instance in aws_instance.cacpm_server : 
//    rsadecrypt(instance.password_data, var.aws_key_pair_id)
//  ]
//  sensitive = true
//}
