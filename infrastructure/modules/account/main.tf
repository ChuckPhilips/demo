variable "subdomain_name_in" {}

resource "aws_route53_zone" "vicertbuddy" {
  name = var.subdomain_name_in
}

output "zone_id" {
  value = aws_route53_zone.vicertbuddy.zone_id
}