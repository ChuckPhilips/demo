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

resource "aws_subnet" "public_a" {
  cidr_block              = cidrsubnet(var.cidr_block_in, 8, 2)
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "${data.aws_region.current.name}a"

  tags = tomap({ Name = "subnet-public-a-${var.postfix_in}" })
}

resource "aws_route_table" "public_a" {
  vpc_id = aws_vpc.main.id

  tags = tomap({ Name = "route-table-public-a-${var.postfix_in}" })
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_a.id
}

resource "aws_route" "public_internet_access_a" {
  route_table_id         = aws_route_table.public_a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_eip" "public_a" {
  vpc = true

  tags = tomap({ Name = "eip-public-a-${var.postfix_in}" })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "public_a" {
  allocation_id = aws_eip.public_a.id
  subnet_id     = aws_subnet.public_a.id

  tags = tomap({ Name = "nat-gateway-public-a-${var.postfix_in}" })
}





resource "aws_subnet" "public_b" {
  cidr_block              = cidrsubnet(var.cidr_block_in, 8, 4)
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "${data.aws_region.current.name}b"

  tags = tomap({ Name = "subnet-public-b-${var.postfix_in}" })
}

resource "aws_route_table" "public_b" {
  vpc_id = aws_vpc.main.id

  tags = tomap({ Name = "route-table-public-b-${var.postfix_in}" })
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_b.id
}

resource "aws_route" "public_internet_access_b" {
  route_table_id         = aws_route_table.public_b.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_eip" "public_b" {
  vpc = true

  tags = tomap({ Name = "eip-public-b-${var.postfix_in}" })
}

resource "aws_nat_gateway" "public_b" {
  allocation_id = aws_eip.public_b.id
  subnet_id     = aws_subnet.public_b.id

  tags = tomap({ Name = "nat-gateway-public-b-${var.postfix_in}" })
}





resource "aws_subnet" "private_a" {
  cidr_block        = cidrsubnet(var.cidr_block_in, 4, 1)
  vpc_id            = aws_vpc.main.id
  availability_zone = "${data.aws_region.current.name}a"

  tags = tomap({ Name = "subnet-private-a-${var.postfix_in}" })
}

resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.main.id

  tags = tomap({ Name = "route-table-private-a-${var.postfix_in}" })
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route" "private_a_internet_out" {
  route_table_id         = aws_route_table.private_a.id
  nat_gateway_id         = aws_nat_gateway.public_a.id
  destination_cidr_block = "0.0.0.0/0"
}






resource "aws_subnet" "private_b" {
  cidr_block        = cidrsubnet(var.cidr_block_in, 4, 2)
  vpc_id            = aws_vpc.main.id
  availability_zone = "${data.aws_region.current.name}b"

  tags = tomap({ Name = "subnet-private-b-${var.postfix_in}" })
}

resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.main.id

  tags = tomap({ Name = "route-table-private-b-${var.postfix_in}" })
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_b.id
}

resource "aws_route" "private_b_internet_out" {
  route_table_id         = aws_route_table.private_b.id
  nat_gateway_id         = aws_nat_gateway.public_b.id
  destination_cidr_block = "0.0.0.0/0"
}