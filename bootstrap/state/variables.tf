variable "project_id" {
  description = "Google Cloud project that owns the Terraform state bucket."
  type        = string
}

variable "bucket_name" {
  description = "Globally unique name for the Terraform state bucket."
  type        = string
  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "The bucket name must contain between 3 and 63 characters."
  }
}

variable "location" {
  description = "Bucket location."
  type        = string
  default     = "us-east1"
}
