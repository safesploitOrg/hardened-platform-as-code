output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_id" {
  value = module.vpc.public_subnet_id
}

output "ec2_public_ip" {
  value = module.ec2.public_ip
}

# SSH Output
output "ssh_command" {
  value = "ssh ec2-user@${module.ec2.public_ip} -i ~/.ssh/id_aws_ed25519"
}
