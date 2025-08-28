variable "ami_id" {
  type        = string
  description = "AMI ID"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID"
}

variable "security_group_id" {
  type        = string
  description = "Security Group ID"
}

variable "key_name" {
  type        = string
  description = "Key pair name"
}

variable "instance_profile" {
  type        = string
  description = "IAM instance profile name"
}

variable "project" {
  type        = string
  description = "Project name"
}
