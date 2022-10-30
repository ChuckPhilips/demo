resource "aws_s3_bucket" "access_logs" {
  bucket = "demo-access-logs"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket                  = aws_s3_bucket.access_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "access_logs_https" {
  statement {
    sid       = "ForceSSLOnlyAccess"
    actions   = ["s3:*"]
    effect    = "Deny"
    resources = ["${aws_s3_bucket.access_logs.arn}/*"]
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

data "aws_iam_policy_document" "access_logs_policy" {
  policy_id = "AWSConsole-AccessLogs-Policy"
  statement {
    sid    = "AllowALBAccountAccessToAccessLogsBucket"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["${data.aws_elb_service_account.current.arn}"]
    }
    actions = ["s3:PutObject"]
    resources = [
      aws_s3_bucket.access_logs.arn,
      "${aws_s3_bucket.access_logs.arn}/${var.workspace_in}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
    ]
  }

  statement {
    sid    = "AWSLogDeliveryWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.s3_access_logs.arn}/${var.workspace_in}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid    = "AWSLogDeliveryAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = ["${aws_s3_bucket.s3_access_logs.arn}"]
  }
}

data "aws_iam_policy_document" "loadbalancer" {
  source_policy_documents = [
    data.aws_iam_policy_document.s3_access_logs_policy.json,
    data.aws_iam_policy_document.loadbalancer_s3_https.json
  ]
}

resource "aws_s3_bucket_policy" "s3_access_logs_policy" {
  bucket     = aws_s3_bucket.s3_access_logs.id
  policy     = data.aws_iam_policy_document.loadbalancer.json
  depends_on = [aws_s3_bucket_public_access_block.s3_access_logs_public_access_block]
}
