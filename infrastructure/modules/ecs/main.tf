variable "postfix_in" {}

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

output "name" {
  value = aws_ecs_cluster.main.name
}