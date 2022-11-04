resource "aws_s3_bucket" "frontend" {
  bucket        = "buddy-demo-frontend"
  force_destroy = true
}

resource "aws_cloudfront_origin_access_identity" "frontend" {
  comment = "OAI for S3 bucket"
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.frontend.json
}

### FRONTEND DISTRIBUTION

resource "tls_private_key" "frontend" {
  algorithm = "RSA"
}

resource "aws_cloudfront_public_key" "frontend" {
  comment     = "test public key"
  encoded_key = tls_private_key.frontend.public_key_pem
  name        = "frontend"
}

resource "aws_cloudfront_key_group" "frontend" {
  items = [aws_cloudfront_public_key.frontend.id]
  name  = "${var.environment_name_in}-frontend"
}

resource "aws_cloudfront_cache_policy" "frontend" {
  name        = "frontend"
  comment     = "Policy with caching disabled"
  default_ttl = 1
  max_ttl     = 1
  min_ttl     = 1
  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

locals {
  origin_id = "${var.environment_name_in}-${aws_s3_bucket.frontend.id}"
}

resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  is_ipv6_enabled     = true
  aliases             = [var.frontend_subdomain_name_in]
  default_root_object = "index.html"
  retain_on_delete    = false #true bi disable distribuciju i moras ju obrisati rucno
  wait_for_deployment = true  #false znaci da terraform NE ceka da distribucija prede iz InProgress u Deployed, ubrzava deploy
  price_class         = "PriceClass_100"

  #   origin_group {
  #     origin_id = "frontend"

  #     failover_criteria {
  #       status_codes = [403, 404, 500, 502]
  #     }

  #     member {
  #       origin_id = "${aws_s3_bucket.frontend.id}-${var.postfix_in}"
  #     }
  #   }

  origin {
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id   = local.origin_id
    #origin_access_control_id = aws_cloudfront_origin_access_identity.frontend.id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.frontend.cloudfront_access_identity_path
    }
  }

  origin {
    domain_name = "frontend.dev.vicertbuddy.pro"
    origin_id   = "frontend"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols = [
        "TLSv1.2",
      ]
    }
  }

  origin {
    domain_name = "api.dev.vicertbuddy.pro"
    origin_id   = "api"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols = [
        "TLSv1.2",
      ]
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.frontend.arn # The ACM certificate must be in US-EAST-1.
    ssl_support_method  = "sni-only"
  }


  default_cache_behavior {
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    #target_origin_id       = local.origin_id
    target_origin_id       = "frontend"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    cache_policy_id        = aws_cloudfront_cache_policy.frontend.id
  }

  ordered_cache_behavior {
    path_pattern    = "/api/*"
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    #target_origin_id       = local.origin_id
    target_origin_id       = "api"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    cache_policy_id        = aws_cloudfront_cache_policy.frontend.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  custom_error_response {
    error_caching_min_ttl = "0"
    error_code            = "404"
    response_code         = "200"
    response_page_path    = "/index.html"
  }

  custom_error_response {
    error_caching_min_ttl = "0"
    error_code            = "403"
    response_code         = "200"
    response_page_path    = "/index.html"
  }

  tags = tomap({ Name = "${var.environment_name_in}-cloudfront" })
}

########################################################################
### CERTIFICATE
########################################################################

resource "aws_route53_record" "frontend" {
  zone_id = var.root_dns_zone_id_in
  name    = var.frontend_subdomain_name_in
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_acm_certificate" "frontend" {
  provider          = aws.us-east-1
  domain_name       = var.frontend_subdomain_name_in
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "frontend_certificate_validation" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.frontend.domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.frontend.domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.frontend.domain_validation_options)[0].resource_record_type
  zone_id         = var.root_dns_zone_id_in
  ttl             = 60
}

resource "aws_acm_certificate_validation" "frontend" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.frontend.arn
  validation_record_fqdns = [aws_route53_record.frontend_certificate_validation.fqdn]
}

########################################################################
### ECS
########################################################################

resource "aws_security_group" "service" {
  description = "Access for the ECS Service"
  name        = "${var.environment_name_in}-service-frontend"
  vpc_id      = var.vpc_id_in

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = var.frontend_container_port_in
    to_port     = var.frontend_container_port_in
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_cluster" "frontend" {
  name = "${var.environment_name_in}-frontend"

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

data "template_file" "frontend" {
  template = file("${path.module}/templates/frontend.json.tpl") # ../../modules/ecs

  vars = {
    app_container_name        = var.frontend_container_name_in
    app_container_image       = var.frontend_container_image_in
    app_container_memory      = "256"
    app_container_port        = var.frontend_container_port_in
    app_log_group_name        = aws_cloudwatch_log_group.frontend.name
    app_log_group_region      = data.aws_region.current.name
    app_awslogs_stream_prefix = var.frontend_container_name_in
  }
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.environment_name_in}-fronted"
  container_definitions    = data.template_file.frontend.rendered
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn
}

resource "aws_ecs_service" "frontend" {
  name                   = "${var.environment_name_in}-frontend"
  cluster                = aws_ecs_cluster.frontend.name
  task_definition        = aws_ecs_task_definition.frontend.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  platform_version       = "1.4.0"
  enable_execute_command = true

  network_configuration {
    subnets         = var.private_subnets_in
    security_groups = [aws_security_group.service.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = var.frontend_container_name_in
    container_port   = var.frontend_container_port_in
  }
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "${var.environment_name_in}-frontend"
  retention_in_days = "14"
}

########################################################################
### TARGET GROUP
########################################################################

resource "aws_lb_target_group" "frontend" {
  name_prefix          = var.environment_name_in
  protocol             = "HTTP"
  vpc_id               = var.vpc_id_in
  target_type          = "ip"
  port                 = var.frontend_container_port_in
  deregistration_delay = 60

  health_check {
    path                = "/"
    port                = var.frontend_container_port_in
    interval            = 60
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  lifecycle {
    create_before_destroy = true
  }

}

########################################################################
### LB LISTENER
########################################################################

resource "aws_lb_listener_rule" "https" {
  listener_arn = var.https_listener_arn_in
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  # condition {
  #   path_pattern {
  #     values = ["/*"]
  #   }
  # }
  condition {
    host_header {
      values = ["frontend.dev.vicertbuddy.pro"]
    }
  }
}

resource "aws_lb_listener_certificate" "https" {
  listener_arn    = var.https_listener_arn_in
  certificate_arn = aws_acm_certificate.app.arn
}


###
resource "aws_route53_record" "app" {
  zone_id = var.root_dns_zone_id_in ##dev.vicertbuddy.pro
  name    = "frontend"
  type    = "CNAME"
  ttl     = "300"

  records = [var.loadbalancer_dns_name_in]
}

resource "aws_acm_certificate" "app" {
  domain_name       = aws_route53_record.app.fqdn
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "app_certificate_validation" {
  allow_overwrite = true
  name            = tolist(aws_acm_certificate.app.domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.app.domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.app.domain_validation_options)[0].resource_record_type
  zone_id         = var.root_dns_zone_id_in
  ttl             = 60
}

resource "aws_acm_certificate_validation" "app" {
  certificate_arn         = aws_acm_certificate.app.arn
  validation_record_fqdns = [aws_route53_record.app_certificate_validation.fqdn]
}