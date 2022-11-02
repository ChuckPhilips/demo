
terraform {
  required_providers {
    aws = {
      configuration_aliases = [aws.us-east-1]
    }
  }
}

variable "environment_name_in" {}
variable "frontend_subdomain_name_in" {}
variable "root_dns_zone_id_in" {}

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

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.frontend.arn # The ACM certificate must be in US-EAST-1.
    ssl_support_method  = "sni-only"
  }


  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.origin_id
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

