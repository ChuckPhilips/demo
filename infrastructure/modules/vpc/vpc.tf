variable "cidr_block_in" {
  description = "Subnet for the vpc."
}

variable "postfix_in" {
  description = "Prefix for the resources."
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}


resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block_in
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = tomap({ Name = "vpc-${var.postfix_in}" })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = tomap({ Name = "internet-gateway-${var.postfix_in}" })
}

module "public_a" {
  source                     = "./public"
  vpc_id_in                  = aws_vpc.main.id
  subnet_in                  = cidrsubnet(var.cidr_block_in, 8, 2)
  identifier_in              = "a"
  postfix_in                 = var.postfix_in
  aws_internet_gateway_id_in = aws_internet_gateway.main.id
}

module "public_b" {
  source                     = "./public"
  vpc_id_in                  = aws_vpc.main.id
  subnet_in                  = cidrsubnet(var.cidr_block_in, 8, 4)
  identifier_in              = "b"
  postfix_in                 = var.postfix_in
  aws_internet_gateway_id_in = aws_internet_gateway.main.id
}

module "private_a" {
  source            = "./private"
  vpc_id_in         = aws_vpc.main.id
  subnet_in         = cidrsubnet(var.cidr_block_in, 4, 1)
  identifier_in     = "a"
  postfix_in        = var.postfix_in
  nat_gateway_id_in = module.public_a.nat_gateway_id
}

module "private_b" {
  source            = "./private"
  vpc_id_in         = aws_vpc.main.id
  subnet_in         = cidrsubnet(var.cidr_block_in, 4, 2)
  identifier_in     = "b"
  postfix_in        = var.postfix_in
  nat_gateway_id_in = module.public_b.nat_gateway_id
}