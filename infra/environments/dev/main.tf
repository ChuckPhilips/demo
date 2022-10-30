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
  postfix         = "${var.environment}-${data.aws_caller_identity.current.account_id}"
  container_image = "454624638483.dkr.ecr.us-east-2.amazonaws.com/backend:${var.backend_app_container_image_tag}"
  proxy_image     = "454624638483.dkr.ecr.us-east-2.amazonaws.com/proxy:${var.backend_proxy_container_image_tag}"

  tags = merge(var.global_tags,
    {
      Environment = var.environment
    }
  )
}

module "account" {
  source = "../../modules/account"
}

module "vpc" {
 source        = "../../modules/vpc"
 cidr_block_in = var.cidr_block
 postfix_in    = "dev"
}


module "loadbalancer" {
 source                = "../../modules/loadbalancer"
 vpc_id_in             = module.vpc.id
 postfix_in            = "dev"
 subnets_in            = module.vpc.public_subnets_ids
 backend_proxy_port_in = var.backend_proxy_container_port
 dns_zone_id_in           = module.account.zone_id
}

#module "ecs" {
#  source = "../../modules/ecs"
#  postfix_in = "dev"
#}

#module "backend" {
#  source                   = "../../modules/backend"
#  ecs_name_in                = module.ecs.name
#  postfix_in               = "dev"
#  app_container_image_in   = local.container_image
#  app_container_port_in    = var.backend_app_container_port
#  proxy_container_image_in = local.proxy_image
#  vpc_id_in                = module.vpc.id
#  subnets_in               = module.vpc.private_subnets_ids
#  target_group_arn_in      = module.loadbalancer.target_group_arn
#  proxy_container_port_in  = var.backend_proxy_container_port
#}
#

module "frontend" {
  source     = "../../modules/frontend"
  postfix_in = "dev"
}
