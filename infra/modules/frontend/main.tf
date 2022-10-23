variable "postfix_in" {}

resource "aws_s3_bucket" "frontend" {
  bucket        = "fcuic-demo-frontend-${var.postfix_in}"
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
  name  = "frontend-${var.postfix_in}"
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

resource "aws_cloudfront_distribution" "frontend" {
  enabled         = true
  is_ipv6_enabled = true
  #aliases             = [var.environment_web_domain_name_in]
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
    origin_id   = "${aws_s3_bucket.frontend.id}-${var.postfix_in}"
    #origin_access_control_id = aws_cloudfront_origin_access_identity.frontend.id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.frontend.cloudfront_access_identity_path
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${aws_s3_bucket.frontend.id}-${var.postfix_in}"
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

  tags = tomap({ Name = "cloudfront-${var.postfix_in}" })
}

output "cloudfront_id" {
  value = aws_cloudfront_distribution.frontend.id
}

output "bucket_name" {
  value = aws_s3_bucket.frontend.id
}