variable "vpc_id" {
  type        = string
  description = "ID of the VPC"
}

variable "allowed_ips" {
  type        = list(string)
  description = "List of allowed CIDRs for SSH"
}

variable "project" {
  type        = string
  description = "Project name for resource tags"
}
