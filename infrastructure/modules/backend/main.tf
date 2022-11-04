resource "aws_security_group" "service" {
  description = "Access for the ECS Service"
  name        = "${var.environment_name_in}-service"
  vpc_id      = var.vpc_id_in

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = var.proxy_container_port_in
    to_port     = var.proxy_container_port_in
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


### TARGET GROUP
resource "aws_lb_target_group" "backend" {
  name_prefix          = var.environment_name_in
  protocol             = "HTTP"
  vpc_id               = var.vpc_id_in
  target_type          = "ip"
  port                 = var.proxy_container_port_in
  deregistration_delay = 60

  health_check {
    path                = "/api/"
    port                = var.proxy_container_port_in
    interval            = 60
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  lifecycle {
    create_before_destroy = true
  }

}

### LISTENER


resource "aws_lb_listener_rule" "https" {
  listener_arn = var.https_listener_arn_in
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  # condition {
  #   path_pattern {
  #     values = ["/api/*"]
  #   }
  # }

  condition {
    host_header {
      values = [var.backend_subdomain_name_in]
    }
  }
}

resource "aws_ecs_cluster" "backend" {
  name = "${var.environment_name_in}-backend"

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

}

resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.environment_name_in}-backend"
  container_definitions    = data.template_file.backend.rendered
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn
}

resource "aws_ecs_service" "backend" {
  name                   = "${var.environment_name_in}-backend"
  cluster                = aws_ecs_cluster.backend.name
  task_definition        = aws_ecs_task_definition.backend.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  platform_version       = "1.4.0"
  enable_execute_command = true

  network_configuration {
    subnets         = var.subnets_in
    security_groups = [aws_security_group.service.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = var.proxy_container_name_in
    container_port   = var.proxy_container_port_in
  }
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "${var.environment_name_in}-nodejs"
  retention_in_days = "14"
}

resource "aws_cloudwatch_log_group" "proxy" {
  name              = "${var.environment_name_in}-nginx"
  retention_in_days = "14"
}