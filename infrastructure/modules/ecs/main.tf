variable "postfix_in" {}
variable "container_image_in" {}
variable "proxy_container_image_in" {}
variable "vpc_id_in" {}
variable "subnets_in" {}
variable "target_group_arn_in" {}
variable "nodejs_port_in" {}
variable "proxy_container_port_in" {}

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

resource "aws_cloudwatch_log_group" "nodejs" {
  name              = "nodejs-${var.postfix_in}"
  retention_in_days = "14"
}

resource "aws_cloudwatch_log_group" "proxy" {
  name              = "nginx-${var.postfix_in}"
  retention_in_days = "14"
}

data "template_file" "api_container_definitions" {
  template = file("${path.module}/templates/musicbox.json.tpl") # ../../modules/ecs

  vars = {
    musicbox_container_name        = "webapp"
    musicbox_container_image       = var.container_image_in
    musicbox_container_memory      = "256"
    musicbox_container_port        = var.nodejs_port_in
    musicbox_log_group_name        = aws_cloudwatch_log_group.nodejs.name
    musicbox_log_group_region      = data.aws_region.current.name
    musicbox_awslogs_stream_prefix = "webapp"
    proxy_container_name           = "nginx"
    proxy_container_image          = var.proxy_container_image_in
    proxy_container_memory         = "256"
    proxy_container_port           = var.proxy_container_port_in
    proxy_log_group_name           = aws_cloudwatch_log_group.proxy.name
    proxy_log_group_region         = data.aws_region.current.name
    proxy_awslogs_stream_prefix    = "proxy"
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
    from_port   = var.proxy_container_port_in
    to_port     = var.proxy_container_port_in
    protocol    = "tcp"
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

  load_balancer {
    target_group_arn = var.target_group_arn_in
    container_name   = "nginx"
    container_port   = var.proxy_container_port_in
  }
}


