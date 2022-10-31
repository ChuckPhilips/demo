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

variable "backend_app_container_port" {
  default = 8080
}

variable "backend_app_container_image_tag" {}

variable "backend_proxy_container_port" {
  default = 80
}

variable "backend_proxy_container_image_tag" {
  default = "latest"
}

variable "global_tags" {
  type = map(any)
  default = {
    "Maintainer" = "Filip"
  }
}

variable "environment_name" {
  default = "dev"
}