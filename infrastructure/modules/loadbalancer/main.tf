########################################################################
### LOADBALANCER
########################################################################
resource "aws_security_group" "loadbalancer" {
  description = "Allow access to Application Load Balancer"
  name        = "${var.environment_name_in}-loadbalancer-sg"
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
  name                       = "${var.environment_name_in}-main-loadbalancer"
  load_balancer_type         = "application"
  drop_invalid_header_fields = true
  enable_deletion_protection = false
  subnets                    = var.subnets_in

  access_logs {
    bucket  = aws_s3_bucket.access_logs.bucket
    prefix  = var.environment_name_in
    enabled = true
  }

  security_groups = [aws_security_group.loadbalancer.id]
}

resource "aws_lb_target_group" "backend" {
  name_prefix          = var.environment_name_in
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


########################################################################
### CERTIFICATE
########################################################################

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


########################################################################
### ACCESS LOGS
########################################################################
resource "aws_s3_bucket" "access_logs" {
  bucket        = var.access_logs_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_acl" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.access_logs.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    id     = "logs"
    status = "Enabled"

    filter {}

    expiration {
      days = 1
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }
  }

  depends_on = [aws_s3_bucket_versioning.access_logs]
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket                  = aws_s3_bucket.access_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "access_logs" {
  bucket     = aws_s3_bucket.access_logs.id
  policy     = data.aws_iam_policy_document.access_logs.json
  depends_on = [aws_s3_bucket_public_access_block.access_logs]
}