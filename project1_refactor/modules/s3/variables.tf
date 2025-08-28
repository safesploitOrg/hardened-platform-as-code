variable "project" {
  type        = string
  description = "Project tag"
}

variable "enable_force_destroy" {
  type        = bool
  # default     = false         # ✅ prod-safe default
  default     = true
  description = "Allow deleting non-empty bucket (use true only in dev/test)"
}

variable "use_kms" {
  type        = bool
  default     = true          # ✅ prefer KMS in prod
}

variable "kms_key_arn" {
  type        = string
  default     = null          # Pass an external CMK if you manage keys centrally
}

variable "enable_lifecycle" {
  type        = bool
  default     = true
}

variable "noncurrent_versions_to_keep" {
  type        = number
  default     = 10
}

variable "archive_after_days" {
  type        = number
  default     = 30            # e.g., transition to IA after 30 days
}

variable "expire_after_days" {
  type        = number
  default     = 365           # e.g., delete after 1 year (adjust to your policy)
}
