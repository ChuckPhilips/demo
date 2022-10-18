variable "vpc_id_in" {}
variable "postfix_in" {}
variable "subnets_in" {}
variable "backend_port_in" {}

resource "aws_security_group" "lb" {
  description = "Allow access to Application Load Balancer"
  name        = "lb-${var.postfix_in}"
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

  #   egress {
  #     protocol    = "tcp"
  #     from_port   = var.api_container_port_in
  #     to_port     = var.api_container_port_in
  #     cidr_blocks = ["0.0.0.0/0"]
  #   }
}

resource "aws_lb" "api" {
  name                       = "main-${var.postfix_in}"
  load_balancer_type         = "application"
  drop_invalid_header_fields = true
  enable_deletion_protection = true
  subnets                    = var.subnets_in

  security_groups = [aws_security_group.lb.id]
}

resource "aws_lb_target_group" "api" {
  name_prefix          = "${var.postfix_in}"
  protocol             = "HTTP"
  vpc_id               = var.vpc_id_in
  target_type          = "ip"
  port                 = var.backend_port_in
  deregistration_delay = 60

  health_check {
    path                = "/"
    interval            = 60
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  lifecycle {
    create_before_destroy = true
  }

}

### need to remove to resolve elbv2-acm-certificate-required config rule
# resource "aws_lb_listener" "api" {
#   load_balancer_arn = aws_lb.api.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type = "redirect"

#     redirect {
#       port        = "443"
#       protocol    = "HTTPS"
#       status_code = "HTTP_301"
#     }
#   }
# }

resource "aws_alb_listener" "main" {
  load_balancer_arn = aws_lb.api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.api.arn
    type             = "forward"
  }
}

output "target_group_arn" {
    value = aws_lb_target_group.api.id
}