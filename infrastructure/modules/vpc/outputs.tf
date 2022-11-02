output "id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = { for identifier, subnet in module.public_subnet : identifier => subnet.id }
}

output "public_subnet_cidr" {
  value = { for identifier, subnet in module.public_subnet : identifier => subnet.cidr_block }
}

output "public_subnets_ids" {
  value = [for subnet in module.public_subnet : subnet.id]
}

output "public_subnets_cidrs" {
  value = [for subnet in module.public_subnet : subnet.cidr_block]
}

output "public_subnet_nat_gateway" {
  value = { for identifier, subnet in module.public_subnet : identifier => subnet.nat_gateway_id }
}

output "private_subnet_id" {
  value = { for identifier, subnet in module.private_subnet : identifier => subnet.id }
}

output "private_subnet_cidr" {
  value = { for identifier, subnet in module.private_subnet : identifier => subnet.cidr_block }
}

output "private_subnets_ids" {
  value = [for subnet in module.private_subnet : subnet.id]
}

output "private_subnets_cidrs" {
  value = [for subnet in module.private_subnet : subnet.cidr_block]
}

output "database_subnet_id" {
  value = { for identifier, subnet in module.database_subnet : identifier => subnet.id }
}

output "database_subnet_cidr" {
  value = { for identifier, subnet in module.database_subnet : identifier => subnet.cidr_block }
}

output "database_subnets_ids" {
  value = [for subnet in module.database_subnet : subnet.id]
}

output "database_subnets_cidrs" {
  value = [for subnet in module.database_subnet : subnet.cidr_block]
}