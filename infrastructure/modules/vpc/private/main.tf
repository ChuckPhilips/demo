variable "vpc_id_in" {}
variable "subnet_in" {}
variable "identifier_in" {}
variable "postfix_in" {}
variable "nat_gateway_id_in" {}

resource "aws_subnet" "private" {
  cidr_block        = var.subnet_in
  vpc_id            = var.vpc_id_in
  availability_zone = "${data.aws_region.current.name}${identifier_in}"

  tags = tomap({ Name = "subnet-private-${var.identifier_in}-${var.postfix_in}" })
}

resource "aws_route_table" "private" {
  vpc_id = var.vpc_id_in

  tags = tomap({ Name = "route-table-private-${var.identifier_in}-${var.postfix_in}" })
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

output "private_subnet_id" {
  value = aws_subnet.private.id
}

output "private_subnet_cidr_block" {
  value = aws_subnet.private.cidr_block
}

output "availability_zone" {
  value = "${data.aws_region.current.name}${identifier_in}"
}