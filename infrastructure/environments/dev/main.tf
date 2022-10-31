variable "environment_name" {
  default = "dev"
}

terraform {
  backend "s3" {
    bucket         = "fcuic-infrastructure-lock"
    key            = "dev-infrastructure.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "terraform-infrastructure-state-lock"
  }

  required_providers {
    aws = {
      version = "4.22.0"
    }
  }
}

locals {
  app_image = join("/", tolist([
    "${var.ecr_repository_url}",
    "${var.backend_repository_name}:${var.backend_app_container_image_tag}"
  ]))
  proxy_image = join("/", tolist([
    "${var.ecr_repository_url}",
    "${var.backend_repository_name}:${var.backend_proxy_container_image_tag}"
  ]))

  tags = merge(var.global_tags,
    {
      Environment = var.environment_name
    }
  )
}

### NE BRISATI
module "account" {
  source = "../../modules/account"
}
###

module "vpc" {
  source              = "../../modules/vpc"
  cidr_block_in       = var.cidr_block
  postfix_in          = var.environment_name
  environment_name_in = var.environment_name
}

module "loadbalancer" {
  source                = "../../modules/loadbalancer"
  vpc_id_in             = module.vpc.id
  subnets_in            = module.vpc.public_subnets_ids
  backend_proxy_port_in = var.backend_proxy_container_port
  dns_zone_id_in        = module.account.zone_id
  environment_name_in   = var.environment_name
}

module "ecs" {
  source              = "../../modules/ecs"
  environment_name_in = var.environment_name
}

module "backend" {
  source                   = "../../modules/backend"
  cluster_name_in          = module.ecs.name
  app_container_image_in   = local.app_image
  app_container_name_in    = "app"
  app_container_port_in    = var.backend_app_container_port
  vpc_id_in                = module.vpc.id
  subnets_in               = module.vpc.private_subnets_ids
  target_group_arn_in      = module.loadbalancer.target_group_arn
  proxy_container_port_in  = var.backend_proxy_container_port
  proxy_container_name_in  = "nginx"
  proxy_container_image_in = local.proxy_image
  environment_name_in      = var.environment_name
}

module "frontend" {
  source              = "../../modules/frontend"
  environment_name_in = var.environment_name
}
