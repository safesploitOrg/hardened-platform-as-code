resource "aws_cloudtrail" "main" {
  name                          = "${var.project}-trail"
  s3_bucket_name                = var.bucket_name
  is_multi_region_trail         = true
  enable_logging                = true
  include_global_service_events = true
}
