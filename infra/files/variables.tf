variable "region" {
  description = "Region."
  default     = "us-east-2"
}

variable "cidr_block" {
  description = "VPC cidr block."
  default     = "172.18.0.0/16"
}

variable "backend_app_container_port" {}
variable "backend_app_container_image_tag" {}

variable "backend_proxy_container_port" {}
variable "backend_proxy_container_image_tag" {}

variable "global_tags" {
  type = map(any)
  default = {
    "Maintainer" = "Filip"
  }
}

variable "ecr_repository_url" {}
variable "frontend_repository_name" {}
variable "backend_repository_name" {}