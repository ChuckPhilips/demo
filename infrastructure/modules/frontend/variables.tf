variable "environment_name_in" {}
variable "frontend_subdomain_name_in" {}
variable "root_dns_zone_id_in" {}
variable "private_subnets_in" {}
variable "frontend_container_name_in" {}
variable "frontend_container_port_in" {}
variable "frontend_container_image_in" {}
variable "vpc_id_in" {}
variable "loadbalancer_dns_name_in" {}
variable "https_listener_arn_in" {}

data "aws_region" "current" {}
