variable "postfix_in" {}
variable "container_image_in" {}
variable "vpc_id_in" {}
variable "subnets_in" {}

data "aws_region" "current" {}

resource "aws_ecs_cluster" "main" {
  name = "cluster-${var.postfix_in}"

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

resource "aws_cloudwatch_log_group" "ecs_task_logs" {
  name              = "api-${var.postfix_in}"
  retention_in_days = "14"
}

data "template_file" "api_container_definitions" {
  template = file("${path.module}/templates/musicbox.json.tpl") # ../../modules/ecs

  vars = {
    musicbox_container_name        = "nginx"
    musicbox_container_image       = var.container_image_in
    musicbox_container_memory      = "256"
    musicbox_container_port        = "80"
    musicbox_log_group_name        = aws_cloudwatch_log_group.ecs_task_logs.name
    musicbox_log_group_region      = data.aws_region.current.name
    musicbox_awslogs_stream_prefix = "nginx"
  }
}

resource "aws_ecs_task_definition" "api" {
  family                   = "api-${var.postfix_in}"
  container_definitions    = data.template_file.api_container_definitions.rendered
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn
}

resource "aws_security_group" "ecs_service" {
  description = "Access for the ECS Service"
  name        = "ecs-service-${var.postfix_in}"
  vpc_id      = var.vpc_id_in

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = "80"
    to_port         = "80"
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "api" {
  name                   = "api-${var.postfix_in}"
  cluster                = aws_ecs_cluster.main.name
  task_definition        = aws_ecs_task_definition.api.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  platform_version       = "1.4.0"
  enable_execute_command = true

  network_configuration {
    subnets         = var.subnets_in
    security_groups = [aws_security_group.ecs_service.id]
  }

#   load_balancer {
#     target_group_arn = var.target_group_arn_in
#     container_name   = "api"
#     container_port   = var.api_container_port_in
#   }

  #depends_on = [aws_lb_listener.api_https]
}