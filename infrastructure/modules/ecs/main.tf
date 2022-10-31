resource "aws_ecs_cluster" "main" {
  name = "${var.environment_name_in}-cluster"

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