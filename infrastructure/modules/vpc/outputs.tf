output "private_a_id" {
  value = module.private_a.private_subnet_id
}

output "private_b_id" {
  value = module.private_b.private_subnet_id
}

output "id" {
  value = aws_vpc.main.id
}

output "public_a_id" {
  value = module.public_a.public_subnet_id
}

output "public_b_id" {
  value = module.public_b.public_subnet_id
}

output "private_a_cidr_block" {
  value = module.private_a.private_subnet_cidr_block
}

output "private_b_cidr_block" {
  value = module.private_b.private_subnet_cidr_block
}

output "public_subnets_ids" {
  value = [module.public_a.public_subnet_id, module.public_b.public_subnet_id]
}

output "private_subnets_ids" {
  value = [module.private_a.private_subnet_id, module.private_b.private_subnet_id]
}

output "public_subnets_cidrs" {
  value = [module.public_a.public_subnet_cidr_block, module.public_b.public_subnet_cidr_block]
}

output "private_subnets_cidrs" {
  value = [module.private_a.private_subnet_cidr_block, module.private_b.private_subnet_cidr_block]
}

output "availability_zones" {
  value = [module.public_a.availability_zone, module.private_a.availability_zone]
}