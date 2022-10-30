variable "vpc_id_in" {}
variable "postfix_in" {}
variable "subnets_in" {}
variable "backend_proxy_port_in" {}
variable "dns_zone_id_in" {}
variable "backend_subdomain_name_in" {
  default = "www.vicertbuddy.pro"
}

resource "aws_security_group" "loadbalancer" {
  description = "Allow access to Application Load Balancer"
  name        = "loadbalancer-${var.postfix_in}"
  vpc_id      = var.vpc_id_in

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "tcp"
    from_port   = var.backend_proxy_port_in
    to_port     = var.backend_proxy_port_in
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "main" {
  name                       = "main-${var.postfix_in}"
  load_balancer_type         = "application"
  drop_invalid_header_fields = true
  enable_deletion_protection = false
  subnets                    = var.subnets_in

  security_groups = [aws_security_group.loadbalancer.id]
}

resource "aws_lb_target_group" "backend" {
  name_prefix          = var.postfix_in
  protocol             = "HTTP"
  vpc_id               = var.vpc_id_in
  target_type          = "ip"
  port                 = var.backend_proxy_port_in
  deregistration_delay = 60

  health_check {
    path                = "/"
    port                = var.backend_proxy_port_in
    interval            = 60
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"

  certificate_arn = aws_acm_certificate_validation.backend.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_route53_record" "backend" {
  zone_id = var.dns_zone_id_in
  name    = var.backend_subdomain_name_in
  type    = "CNAME"
  ttl     = "300"

  records = [aws_lb.main.dns_name]
}

resource "aws_acm_certificate" "backend" {
  domain_name       = aws_route53_record.backend.fqdn
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "certificate_validation" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.backend.domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.backend.domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.backend.domain_validation_options)[0].resource_record_type
  zone_id         = var.dns_zone_id_in
  ttl             = 60
}

resource "aws_acm_certificate_validation" "backend" {
  certificate_arn         = aws_acm_certificate.backend.arn
  validation_record_fqdns = [aws_route53_record.certificate_validation.fqdn]
}


output "target_group_arn" {
  value = aws_lb_target_group.backend.id
}