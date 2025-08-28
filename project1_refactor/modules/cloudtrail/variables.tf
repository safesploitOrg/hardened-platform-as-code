variable "project" {
  type        = string
  description = "Project prefix for naming"
}

variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket for CloudTrail logs"
}

variable "account_id" {
  type        = string
  description = "AWS account ID"
}
