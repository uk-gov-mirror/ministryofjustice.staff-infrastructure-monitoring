terraform {
  backend "s3" {
    region     = "eu-west-2"
    bucket     = "pttp-ci-infrastructure-ima-client-core-tf-state"
    lock_table = "pttp-ci-infrastructure-ima-client-core-tf-lock-table"
  }
}

provider "aws" {
  region  = var.aws_region
  alias   = "env"
  profile = terraform.workspace

  assume_role {
    role_arn = var.assume_role
  }
}

provider "grafana" {
  url  = var.grafana_url
  auth = "${var.grafana_admin_username}:${var.grafana_admin_password}"
}

module "label_pttp" {
  source          = "./modules/label"
  label_namespace = "pttp"
  owner-email     = var.owner-email
  is-production   = var.is-production
  label_status    = "legacy"
  label_notes     = "To be removed post CIDR block change"
}

module "label" {
  source          = "./modules/label"
  label_namespace = "staff-infra"
  owner-email     = var.owner-email
  is-production   = var.is-production
}

module "monitoring_platform" {
  source = "./modules/monitoring_platform"

  prefix = module.label_pttp.id
  tags   = module.label_pttp.tags

  transit_gateway_id             = var.transit_gateway_id
  enable_transit_gateway         = var.enable_transit_gateway
  transit_gateway_route_table_id = var.transit_gateway_route_table_id

  vpc_cidr_block             = "10.180.88.0/21"
  private_subnet_cidr_blocks = ["10.180.88.0/24", "10.180.89.0/24", "10.180.90.0/24"]
  public_subnet_cidr_blocks  = ["10.180.91.0/24", "10.180.92.0/24", "10.180.93.0/24"]
  storage_key_arn            = module.prometheus-thanos-storage.kms_key_arn

  providers = {
    aws = aws.env
  }
}

module "grafana" {
  source = "./modules/grafana"

  aws_region   = var.aws_region
  prefix_pttp  = module.label_pttp.id
  prefix       = module.label.id
  tags         = module.label_pttp.tags
  short_prefix = module.label_pttp.stage

  vpc                = module.monitoring_platform.vpc_id
  cluster_id         = module.monitoring_platform.cluster_id
  public_subnet_ids  = module.monitoring_platform.public_subnet_ids
  private_subnet_ids = module.monitoring_platform.private_subnet_ids

  execution_role_arn      = module.monitoring_platform.execution_role_arn
  rds_monitoring_role_arn = module.monitoring_platform.rds_monitoring_role_arn

  grafana_image_repository_url          = var.grafana_image_repository_url
  grafana_image_renderer_repository_url = var.grafana_image_renderer_repository_url

  db_name        = var.grafana_db_name
  db_endpoint    = var.grafana_db_endpoint
  db_username    = var.grafana_db_username
  db_password    = var.grafana_db_password
  admin_username = var.grafana_admin_username
  admin_password = var.grafana_admin_password

  vpn_hosted_zone_id     = var.vpn_hosted_zone_id
  vpn_hosted_zone_domain = var.vpn_hosted_zone_domain
  domain_prefix          = var.domain_prefix

  azure_ad_auth_url      = var.azure_ad_auth_url
  azure_ad_token_url     = var.azure_ad_token_url
  azure_ad_client_id     = var.azure_ad_client_id
  azure_ad_client_secret = var.azure_ad_client_secret

  smtp_user     = var.smtp_user
  smtp_password = var.smtp_password

  sns_subscribers = split(",", var.sns_subscribers)

  storage_bucket_arn = module.grafana-image-storage.bucket_arn

  lb_access_logging_bucket_name = module.grafana_lb_access_logging.bucket_name

  providers = {
    aws = aws.env
  }
}

module "grafana_lb_access_logging" {
  source = "./modules/s3_bucket"

  name                           = "grafana-lb-access-logging"
  prefix_pttp                    = module.label_pttp.id
  tags                           = module.label_pttp.tags
  versioning_enabled             = false
  encryption_enabled             = false
  attach_elb_log_delivery_policy = true

  providers = {
    aws = aws.env
  }
}

module "prometheus" {
  source = "./modules/prometheus"

  enable_compactor = "false"

  aws_region  = var.aws_region
  prefix_pttp = module.label_pttp.id
  prefix      = module.label.id
  tags        = module.label_pttp.tags

  vpc                = module.monitoring_platform.vpc_id
  cluster_id         = module.monitoring_platform.cluster_id
  public_subnet_ids  = module.monitoring_platform.public_subnet_ids
  private_subnet_ids = module.monitoring_platform.private_subnet_ids
  fargate_count      = 1

  execution_role_arn = module.monitoring_platform.execution_role_arn

  thanos_image_repository_url = var.thanos_image_repository_url

  storage_bucket_arn = module.prometheus-thanos-storage.bucket_arn
  storage_key_arn    = module.prometheus-thanos-storage.kms_key_arn
  storage_key_id     = module.prometheus-thanos-storage.kms_key_id

  lb_access_logging_bucket_name = module.prometheus_lb_access_logging.bucket_name

  providers = {
    aws = aws.env
  }
}

module "prometheus_lb_access_logging" {
  source = "./modules/s3_bucket"

  name                           = "prometheus-lb-access-logging"
  prefix_pttp                    = module.label_pttp.id
  tags                           = module.label_pttp.tags
  versioning_enabled             = false
  encryption_enabled             = false
  attach_elb_log_delivery_policy = true

  providers = {
    aws = aws.env
  }
}

module "snmp_exporter" {
  source = "./modules/snmp_exporter"

  aws_region  = var.aws_region
  prefix_pttp = module.label_pttp.id
  prefix      = module.label.id
  tags        = module.label_pttp.tags

  vpc                = module.monitoring_platform.vpc_id
  cluster_id         = module.monitoring_platform.cluster_id
  public_subnet_ids  = module.monitoring_platform.public_subnet_ids
  private_subnet_ids = module.monitoring_platform.private_subnet_ids

  execution_role_arn = module.monitoring_platform.execution_role_arn

  lb_access_logging_bucket_name = module.snmp_exporter_lb_access_logging.bucket_name

  providers = {
    aws = aws.env
  }
}

module "snmp_exporter_lb_access_logging" {
  source = "./modules/s3_bucket"

  name                           = "snmp-exporter-lb-access-logging"
  prefix_pttp                    = module.label_pttp.id
  tags                           = module.label_pttp.tags
  versioning_enabled             = false
  encryption_enabled             = false
  attach_elb_log_delivery_policy = true

  providers = {
    aws = aws.env
  }
}

module "blackbox_exporter" {
  source = "./modules/blackbox_exporter"

  aws_region  = var.aws_region
  prefix_pttp = module.label_pttp.id
  prefix      = module.label.id
  tags        = module.label_pttp.tags

  vpc                = module.monitoring_platform.vpc_id
  cluster_id         = module.monitoring_platform.cluster_id
  public_subnet_ids  = module.monitoring_platform.public_subnet_ids
  private_subnet_ids = module.monitoring_platform.private_subnet_ids

  execution_role_arn = module.monitoring_platform.execution_role_arn

  lb_access_logging_bucket_name = module.blackbox_exporter_lb_access_logging.bucket_name

  providers = {
    aws = aws.env
  }
}

module "blackbox_exporter_lb_access_logging" {
  source = "./modules/s3_bucket"

  name                           = "blackbox-exporter-lb-access-logging"
  prefix_pttp                    = module.label_pttp.id
  tags                           = module.label_pttp.tags
  versioning_enabled             = false
  encryption_enabled             = false
  attach_elb_log_delivery_policy = true

  providers = {
    aws = aws.env
  }
}

module "s3_access_logging" {
  source = "./modules/s3_bucket"

  name               = "s3-access-logging"
  prefix_pttp        = module.label_pttp.id
  tags               = module.label_pttp.tags
  acl                = "log-delivery-write"
  versioning_enabled = false

  providers = {
    aws = aws.env
  }
}

module "prometheus-thanos-storage" {
  source = "./modules/s3_bucket"

  name        = "thanos-storage"
  prefix_pttp = module.label_pttp.id
  tags        = module.label_pttp.tags

  logging = {
    target_bucket = module.s3_access_logging.bucket_name
  }

  providers = {
    aws = aws.env
  }
}

module "grafana-image-storage" {
  source = "./modules/s3_bucket"

  name               = "grafana-image-storage"
  prefix_pttp        = module.label_pttp.id
  tags               = module.label_pttp.tags
  encryption_enabled = false
  versioning_enabled = false

  logging = {
    target_bucket = module.s3_access_logging.bucket_name
  }

  providers = {
    aws = aws.env
  }
}
