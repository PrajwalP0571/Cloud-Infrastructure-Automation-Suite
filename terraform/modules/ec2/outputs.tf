output "instance_ids" {
  description = "IDs of the provisioned EC2 instances"
  value       = aws_instance.app[*].id
}

output "public_ips" {
  description = "Public IP addresses of the instances"
  value       = aws_instance.app[*].public_ip
}

output "private_ips" {
  description = "Private IP addresses of the instances"
  value       = aws_instance.app[*].private_ip
}

output "iam_role_name" {
  description = "Name of the IAM role attached to instances"
  value       = aws_iam_role.ec2_role.name
}
