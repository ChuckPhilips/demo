variable "vpc_id_in" {}
variable "subnets_in" {}
variable "backend_proxy_port_in" {}
variable "dns_zone_id_in" {}
variable "backend_subdomain_name_in" {
  default = "www.vicertbuddy.pro"
}
variable "access_logs_bucket_name" {
  default = "demo-loadbalancer-main-access-logs"
}
variable "environment_name_in" {}