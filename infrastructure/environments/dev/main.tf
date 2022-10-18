variable "region" {
  description = "Region."
  default     = "us-east-2"
}

variable "cidr_block" {
  description = "VPC cidr block."
  default     = "172.18.0.0/16"
}

variable "environment" {
  type        = string
  description = "Environment name."
  default     = "dev"
}

variable "image_tag" {}

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
  default_tags {
    tags = local.tags
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}
data "aws_elb_service_account" "current" {}

variable "global_tags" {
  type = map(any)
  default = {
    "Maintainer" = "Filip"
  }
}


locals {
  postfix         = "${var.environment}-${data.aws_caller_identity.current.account_id}"
  container_image = "454624638483.dkr.ecr.us-east-2.amazonaws.com/backend:${var.image_tag}"
  tags = merge(var.global_tags,
    {
      Environment = var.environment
    }
  )
}

module "vpc" {
  source        = "../../modules/vpc"
  cidr_block_in = var.cidr_block
  postfix_in    = "dev"
}

module "ecs" {
   source = "../../modules/ecs"
   postfix_in = "dev"
   container_image_in = local.container_image
   vpc_id_in = module.vpc.id
   subnets_in = module.vpc.private_subnets_ids
}
