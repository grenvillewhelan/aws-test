output "pingds_target_group_arn" {
   value = "aws_lb_target_group.pingds.arn"
}

output "drives" {
  value = jsonencode(var.pingds_drives)
}
