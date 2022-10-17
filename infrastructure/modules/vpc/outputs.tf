output "private_a_id" {
  value = aws_subnet.private_a.id
}

output "private_b_id" {
  value = aws_subnet.private_b.id
}

output "id" {
  value = aws_vpc.main.id
}

output "public_a_id" {
  value = aws_subnet.public_a.id
}

output "public_b_id" {
  value = aws_subnet.public_b.id
}

output "private_a_cidr_block" {
  value = aws_subnet.private_a.cidr_block
}

output "private_b_cidr_block" {
  value = aws_subnet.private_b.cidr_block
}

output "public_subnets_ids" {
  value = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "private_subnets_ids" {
  value = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "public_subnets_cidrs" {
  value = [aws_subnet.public_a.cidr_block, aws_subnet.public_b.cidr_block]
}

output "private_subnets_cidrs" {
  value = [aws_subnet.private_a.cidr_block, aws_subnet.private_b.cidr_block]
}

output "availability_zones" {
  value = ["${data.aws_region.current.name}a", "${data.aws_region.current.name}b"]
}