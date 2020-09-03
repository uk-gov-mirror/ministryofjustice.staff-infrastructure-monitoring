terraform {
  required_version = "> 0.12.0"

  backend "s3" {
    region     = "eu-west-2"
    bucket     = "pttp-default-monitoring-tf-remote-state"
    key        = "terraform/v1/state"
    lock_table = "pttp-default-monitoring-terrafrom-remote-state-lock-dynamo"
  }
}

provider "aws" {
  version = "~> 2.52"
}

data "aws_region" "current_region" {}

module "label" {
  source  = "cloudposse/label/null"
  version = "0.16.0"

  namespace = "pttp"
  stage     = terraform.workspace
  name      = "monitoring"
  delimiter = "-"

  tags = {
    "business-unit" = "MoJO"
    "application"   = "monitoring-and-alerting",
    "is-production" = tostring(var.is-production),
    "owner"         = var.owner-email

    "environment-name" = "global"
    "source-code"      = "https://github.com/ministryofjustice/staff-infrastructure-monitoring"
  }
}

# Load Balancer
  # Listener
  # Target group
# Networking
  # VPC
  # Availability zones
  # Subnets
# Cluster
  # Service
  # Task definition
    # Docker image

# Security groups (maybe)
