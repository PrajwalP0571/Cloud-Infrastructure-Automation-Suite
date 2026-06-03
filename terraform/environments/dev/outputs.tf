output "vpc_id" {
  value = module.vpc.vpc_id
}

output "app_instance_ids" {
  value = module.ec2_app.instance_ids
}

output "app_public_ips" {
  value = module.ec2_app.public_ips
}

output "monitoring_public_ip" {
  value = module.ec2_monitoring.public_ips
}
