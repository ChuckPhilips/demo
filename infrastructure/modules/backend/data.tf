data "aws_region" "current" {}

data "template_file" "backend" {
  template = file("${path.module}/templates/backend.json.tpl") # ../../modules/ecs

  vars = {
    app_container_name          = var.app_container_name_in
    app_container_image         = var.app_container_image_in
    app_container_memory        = "256"
    app_container_port          = var.app_container_port_in
    app_log_group_name          = aws_cloudwatch_log_group.app.name
    app_log_group_region        = data.aws_region.current.name
    app_awslogs_stream_prefix   = var.app_container_name_in
    proxy_container_name        = var.proxy_container_name_in
    proxy_container_image       = var.proxy_container_image_in
    proxy_container_memory      = "256"
    proxy_container_port        = var.proxy_container_port_in
    proxy_log_group_name        = aws_cloudwatch_log_group.proxy.name
    proxy_log_group_region      = data.aws_region.current.name
    proxy_awslogs_stream_prefix = var.proxy_container_name_in
  }
}