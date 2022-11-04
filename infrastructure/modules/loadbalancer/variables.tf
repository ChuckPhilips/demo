variable "vpc_id_in" {}
variable "subnets_in" {}
variable "root_dns_zone_id_in" {}
variable "backend_subdomain_name_in" {}
variable "access_logs_bucket_name" {
  default = "demo-loadbalancer-main-access-logs"
}
variable "environment_name_in" {}
variable "backend_proxy_container_port_in" {}
variable "frontend_container_port_in" {}