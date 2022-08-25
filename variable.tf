variable "prefix" {
  type        = string
  description = "Prefix of the name"
}

variable "source_bucket_name" {
  type        = string
  description = "Name of the source bucket"
}

variable "destination_bucket_name" {
  type        = string
  description = "Name of the destination bucket"
}

variable "does_destination_bucket_exist" {
  type        = bool
  description = "Whether the destination bucket exist or not. If this is true, destination_bucket_key_arn is required"
}

variable "destination_bucket_key_arn" {
  type        = string
  description = "Arn of kms key used for destination bucket encryption"
  default     = ""
}
