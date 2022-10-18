variable "vpc_id_in" {}
variable "subnet_in" {}
variable "identifier_in" {}
variable "postfix_in" {}
variable "internet_gateway_id_in" {}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}


resource "aws_subnet" "public" {
  cidr_block              = var.subnet_in
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "${data.aws_region.current.name}${identifier_in}"

  tags = tomap({ Name = "subnet-public-${var.identifier_in}-${var.postfix_in}" })
}

resource "aws_route_table" "public" {
  vpc_id = var.vpc_id_in

  tags = tomap({ Name = "route-table-public-${var.identifier_in}-${var.postfix_in}" })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.internet_gateway_id_in
}

resource "aws_eip" "public" {
  vpc  = true
  tags = tomap({ Name = "eip-public-${var.identifier_in}-${var.postfix_in}" })
}

resource "aws_nat_gateway" "public" {
  allocation_id = aws_eip.public.id
  subnet_id     = aws_subnet.public.id

  tags = tomap({ Name = "nat-gateway-public-${var.identifier_in}-${var.postfix_in}" })
}


output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "public_subnet_cidr_block" {
  value = aws_subnet.public.cidr_block
}

output "availability_zone" {
  value = "${data.aws_region.current.name}${var.identifier_in}"
}

output "nat_gateway_id" {
  value = aws_nat_gateway.public.id
}