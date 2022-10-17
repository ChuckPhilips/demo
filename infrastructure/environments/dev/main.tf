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
  region  = var.region
  profile = "ecs-course"
  default_tags {
    tags = local.tags
  }
}

module "vpc" {
    source        = "../../modules/vpc"
    cidr_block_in = var.cidr_block
}
