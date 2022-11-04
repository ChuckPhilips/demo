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

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

locals {
  tags = merge(var.global_tags, {
    Environment = var.environment_name
    }
  )
  subdomain_name          = "${var.environment_name}.${var.domain_name}"
  backend_subdomain_name  = "api.${local.subdomain_name}"
  frontend_subdomain_name = "app.${local.subdomain_name}"
}

### NE BRISATI
module "account" {
  source            = "../../modules/account"
  subdomain_name_in = local.subdomain_name
}
###

module "vpc" {
  source              = "../../modules/vpc"
  cidr_block_in       = var.cidr_block
  environment_name_in = var.environment_name
}

module "loadbalancer" {
  source                    = "../../modules/loadbalancer"
  vpc_id_in                 = module.vpc.id
  subnets_in                = module.vpc.public_subnets_ids
  root_dns_zone_id_in       = module.account.zone_id
  environment_name_in       = var.environment_name
  backend_subdomain_name_in = local.backend_subdomain_name
  backend_proxy_container_port_in = var.backend_proxy_container_port
  frontend_container_port_in = var.frontend_container_port
}

module "backend" {
  source                   = "../../modules/backend"
  app_container_image_in   = local.app_image
  app_container_name_in    = "app"
  app_container_port_in    = var.backend_app_container_port
  vpc_id_in                = module.vpc.id
  subnets_in               = module.vpc.private_subnets_ids
  proxy_container_port_in  = var.backend_proxy_container_port
  proxy_container_name_in  = "nginx"
  proxy_container_image_in = local.proxy_image
  environment_name_in      = var.environment_name
  https_listener_arn_in      = module.loadbalancer.https_listener_arn
  backend_subdomain_name_in = local.backend_subdomain_name
}

module "frontend" {
  source                     = "../../modules/frontend"
  environment_name_in        = var.environment_name
  frontend_subdomain_name_in = local.frontend_subdomain_name
  root_dns_zone_id_in        = module.account.zone_id
  private_subnets_in               = module.vpc.private_subnets_ids 
  frontend_container_image_in = local.frontend_image
  frontend_container_name_in = "nginxreact"
  https_listener_arn_in      = module.loadbalancer.https_listener_arn
  frontend_container_port_in  = var.frontend_container_port
  loadbalancer_dns_name_in    = module.loadbalancer.dns_name
  vpc_id_in = module.vpc.id
  providers = {
    aws           = aws,
    aws.us-east-1 = aws.us-east-1
  }

}

# #module "database" {}

# #module "serverless" {}

# #module config {}

# output "cloudfront_id" {
#   value = module.frontend.cloudfront_id
# }

# output "frontend_bucket_name" {
#   value = module.frontend.bucket_name
# }

# output "domain_name" {
#   value = local.frontend_subdomain_name
# }

