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

provider "aws" {
  region = var.region
}

locals {
  tags = merge(var.global_tags, {
      Environment = var.environment_name
    }
  )
  subdomain_name = "${var.environment_name}.${var.domain_name}"
  backend_subdomain_name = "api.${local.subdomain_name}"
  frontend_subdomain_name = "app.${local.subdomain_name}"
}

### NE BRISATI
module "account" {
  source = "../../modules/account"
  subdomain_name_in = local.subdomain_name
}
###

# module "vpc" {
#   source              = "../../modules/vpc"
#   cidr_block_in       = var.cidr_block
#   environment_name_in = var.environment_name
#   subdomain_name_in   = var.subdomain_name
# }

# module "loadbalancer" {
#   source                = "../../modules/loadbalancer"
#   vpc_id_in             = module.vpc.id
#   subnets_in            = module.vpc.public_subnets_ids
#   backend_proxy_port_in = var.backend_proxy_container_port
#   dns_zone_id_in        = module.account.zone_id
#   environment_name_in   = var.environment_name
#   backend_subdomain_name_in = local.backend_subdomain_name
# }

#module "backend" {
#  source                   = "../../modules/backend"
#  app_container_image_in   = local.app_image
#  app_container_name_in    = "app"
#  app_container_port_in    = var.backend_app_container_port
#  vpc_id_in                = module.vpc.id
#  subnets_in               = module.vpc.private_subnets_ids
#  target_group_arn_in      = module.loadbalancer.target_group_arn
#  proxy_container_port_in  = var.backend_proxy_container_port
#  proxy_container_name_in  = "nginx"
#  proxy_container_image_in = local.proxy_image
#  environment_name_in      = var.environment_name
#}

#module "frontend" {
#  source              = "../../modules/frontend"
#  environment_name_in = var.environment_name
#  frontend_subdomain_name_in = local.frontend_subdomain_name
#}

# output "cloudfront_id" {
#   value = module.frontend.cloudfront_id
# }

# output "frontend_bucket_name" {
#   value = module.frontend.bucket_name
# }