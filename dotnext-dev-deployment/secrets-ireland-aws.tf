resource "aws_key_pair" "ireland_admin_access" {
  key_name   = "admin_access"
  public_key = tls_private_key.global_ssh_key.public_key_openssh
  provider = aws.ireland

  lifecycle {
      ignore_changes = [ public_key ]
  }
}
