#################### General ####################
variable "aws_region" {
  type = string
}

variable "prefix_pttp" {
  type = string
}

variable "prefix" {
  type = string
}

variable "short_prefix" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "vpc" {
  type = string
}

variable "domain_prefix" {
  type = string
}

variable "vpn_hosted_zone_domain" {
  type = string
}

variable "vpn_hosted_zone_id" {
  type = string
}

variable "cluster_id" {
  type = string
}

####################  S3 Storage ####################

variable "storage_bucket_arn" {
  description = "ARN of the S3 Bucket to be used for image storage"
  type        = string
}

################## Load Balancer Access Logging Bucket ####################

variable "lb_access_logging_bucket_name" {
  description = "Load balancer access logging AWS S3 bucket"
  type        = string
}

#################### Networking ####################
variable "public_subnet_ids" {
  type = list
}

variable "private_subnet_ids" {
  type = list
}

#################### Fargate ####################
variable "execution_role_arn" {
  type = string
}

variable "host_port" {
  description = "Port exposed by the load balancer for the service"
  default     = 443
}

variable "container_port" {
  description = "Port exposed by the docker image to redirect traffic to"
  default     = 3000
}

variable "grafana_image_repository_url" {
  description = "Docker image to run in the ECS cluster"
  type        = string
}

variable "grafana_image_renderer_repository_url" {
  description = "Docker image to run in the ECS cluster"
  type        = string
}

variable "fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default     = "256"
}

variable "fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  default     = "512"
}

variable "fargate_count" {
  description = "Number of docker containers to run"
  default     = "2"
}

#################### Database ####################
variable "db_port" {
  default = 5432
}

variable "db_name" {
  type = string
}

variable "db_endpoint" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
}

variable "db_backup_retention_period" {
  description = "The days to retain database backups for"
  default     = 7
}

variable "rds_monitoring_role_arn" {
  type = string
}

#################### User details ####################
variable "admin_username" {
  type = string
}

variable "admin_password" {
  type = string
}


#################### SMTP details ####################
variable "smtp_user" {
  type = string
}

variable "smtp_password" {
  type = string
}

#################### Azure AD ####################
variable "azure_ad_client_id" {
  type = string
}

variable "azure_ad_client_secret" {
  type = string
}

variable "azure_ad_auth_url" {
  type = string
}

variable "azure_ad_token_url" {
  type = string
}

variable "sns_subscribers" {
  type    = list
  default = []
}
