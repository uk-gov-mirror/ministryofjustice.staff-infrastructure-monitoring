variable "az_count" {
  description = "Number of AZs to cover in a given AWS region"
  default     = "3"
}

variable "prefix" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "enable_transit_gateway" {
  type    = bool
  default = false
}

variable "transit_gateway_id" {
  type = string
}

variable "transit_gateway_route_table_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "private_subnet_cidr_blocks" {
  type = list(string)
}

variable "public_subnet_cidr_blocks" {
  type = list(string)
}

variable "is_eks_enabled" {
  type    = bool
  default = false
}

variable "storage_bucket_arn" {
  type    = string
  default = ""
}

variable "storage_key_arn" {
  description = "ARN of the long-term storage S3 Bucket KMS Key"
  type        = string
}
