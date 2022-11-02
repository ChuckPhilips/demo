variable "vpc_id_in" {}
variable "subnet_in" {}
variable "identifier_in" {}
variable "nat_gateway_id_in" {}
variable "environment_name_in" {}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_subnet" "private" {
  cidr_block        = var.subnet_in
  vpc_id            = var.vpc_id_in
  availability_zone = "${data.aws_region.current.name}${var.identifier_in}"

  tags = tomap({ Name = "${var.environment_name_in}-private-${var.identifier_in}" })
}

resource "aws_route_table" "private" {
  vpc_id = var.vpc_id_in

  tags = tomap({ Name = "${var.environment_name_in}-route-table-private-${var.identifier_in}" })
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route" "private_internet_out" {
  route_table_id         = aws_route_table.private.id
  nat_gateway_id         = var.nat_gateway_id_in
  destination_cidr_block = "0.0.0.0/0"
}

output "id" {
  value = aws_subnet.private.id
}

output "cidr_block" {
  value = aws_subnet.private.cidr_block
}