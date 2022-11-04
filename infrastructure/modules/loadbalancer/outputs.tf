output "arn" {
  value = aws_lb.main.arn
}

output "dns_name" {
  value = aws_lb.main.dns_name
}

output "https_listener_arn" {
  value = aws_lb_listener.https.arn
}