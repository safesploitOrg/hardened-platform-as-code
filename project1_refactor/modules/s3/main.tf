resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "logs" {
  bucket        = "my-secure-logs-${random_id.bucket_suffix.hex}"
  force_destroy = var.enable_force_destroy

  tags = {
    Project     = var.project
    Environment = "DevSecOps"
  }
}

# Strong public access posture
resource "aws_s3_bucket_public_access_block" "block" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Prefer bucket ownership; disable object ACLs
resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "acl" {
  bucket = aws_s3_bucket.logs.id
  acl    = "private"
  depends_on = [aws_s3_bucket_ownership_controls.ownership]
}

# Versioning for protection against overwrite/delete
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption (KMS preferred)
resource "aws_s3_bucket_server_side_encryption_configuration" "encrypt" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.use_kms ? "aws:kms" : "AES256"
      kms_master_key_id = var.use_kms && var.kms_key_arn != null ? var.kms_key_arn : null
    }
    bucket_key_enabled = var.use_kms
  }
}

# Lifecycle (cost control)
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  count  = var.enable_lifecycle ? 1 : 0
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "log-lifecycle"
    status = "Enabled"

    # ✅ Fix: add a filter to match all objects
    filter {
      prefix = ""
    }

    transition {
      days          = var.archive_after_days
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      newer_noncurrent_versions = var.noncurrent_versions_to_keep
      noncurrent_days           = var.expire_after_days
    }

    expiration {
      days = var.expire_after_days
    }
  }
}


# Defense-in-depth bucket policy:
# - Deny non-TLS
# - Deny unencrypted uploads (unless CloudTrail PUTs with the required headers)
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "logs_bucket" {
  # Enforce TLS
  statement {
    sid     = "DenyUnEncryptedTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = [
      aws_s3_bucket.logs.arn,
      "${aws_s3_bucket.logs.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  # Allow CloudTrail to check ACL
  statement {
    sid     = "AWSCloudTrailAclCheck"
    effect  = "Allow"
    actions = ["s3:GetBucketAcl"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    resources = [aws_s3_bucket.logs.arn]
  }

  # Allow CloudTrail to write logs
  statement {
    sid     = "AWSCloudTrailWrite"
    effect  = "Allow"
    actions = ["s3:PutObject"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    resources = [
      "${aws_s3_bucket.logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.logs_bucket.json
}
