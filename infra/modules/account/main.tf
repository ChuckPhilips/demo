resource "aws_route53_zone" "vicertbuddy" {
  name = "vicertbuddy.pro."
}

output "zone_id" {
  value = aws_route53_zone.vicertbuddy.zone_id
}