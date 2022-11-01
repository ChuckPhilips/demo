variable "cidr_block_in" {
  description = "Subnet for the vpc."
}

variable "postfix_in" {
  description = "Prefix for the resources."
}
variable "environment_name_in" {}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}


resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block_in
  enable_dns_support   = true
  enable_dns_hostnames = true

  lifecycle {
    create_before_destroy = true
  }

  tags = tomap({ Name = "${var.environment_name_in}-vpc" })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = tomap({ Name = "${var.environment_name_in}-internet-gateway" })
}

module "public_subnet" {
  for_each = tomap({
    "a" = cidrsubnet(var.cidr_block_in, 8, 2)
    "b" = cidrsubnet(var.cidr_block_in, 8, 4)
    "c" = cidrsubnet(var.cidr_block_in, 8, 6)
  })
  source                 = "./public"
  vpc_id_in              = aws_vpc.main.id
  subnet_in              = each.value
  identifier_in          = each.key
  environment_name_in    = var.environment_name_in
  internet_gateway_id_in = aws_internet_gateway.main.id
}

module "private_subnet" {
  for_each = tomap({
    "a" = cidrsubnet(var.cidr_block_in, 4, 1)
    "b" = cidrsubnet(var.cidr_block_in, 4, 2)
    "c" = cidrsubnet(var.cidr_block_in, 4, 3)
  })
  source              = "./private"
  vpc_id_in           = aws_vpc.main.id
  subnet_in           = each.value
  identifier_in       = each.key
  environment_name_in = var.environment_name_in
  nat_gateway_id_in   = module.public_subnet[each.key].nat_gateway_id
}