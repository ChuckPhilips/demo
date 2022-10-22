### FRONTEND 

data "aws_iam_policy_document" "frontend_oai" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.frontend.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.frontend.iam_arn]
    }
  }
}

data "aws_iam_policy_document" "frontend_https" {
  statement {
    sid       = "ForceSSLOnlyAccess"
    actions   = ["s3:*"]
    effect    = "Deny"
    resources = ["${aws_s3_bucket.frontend.arn}/*"]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

data "aws_iam_policy_document" "frontend" {
  source_policy_documents = [
    data.aws_iam_policy_document.frontend_oai.json,
    data.aws_iam_policy_document.frontend_https.json
  ]
}