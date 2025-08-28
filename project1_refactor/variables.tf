variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "project" {
  description = "Project or environment name prefix"
  type        = string
}

variable "key_name" {
  description = "SSH key name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "allowed_ips" {
  description = "List of CIDRs allowed SSH access"
  type        = list(string)
}


variable "public_key" {
  description = "SSH public key to use for EC2 instances"
  type        = string
}


# vpc module
variable "vpc_cidr" {
  type = string
}

variable "public_subnet_cidr" {
  type = string
}

variable "availability_zone" {
  type        = string
}

# data AMI
variable "ami_owner" {
  type    = string
  # default = "amazon"
}

variable "ami_name_pattern" {
  type    = string
  # default = "amzn2-ami-hvm-*-x86_64-gp2"
}
