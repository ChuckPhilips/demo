data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_elb_service_account" "current" {}

locals {
  elb_account_permissions = join("/", tolist([
    "${aws_s3_bucket.access_logs.arn}",
    "${var.environment_name_in}",
    "AWSLogs",
    "${data.aws_caller_identity.current.account_id}",
    "*"
  ]))
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

data "aws_iam_policy_document" "access_logs_loadbalancer" {
  policy_id = "AWSConsole-AccessLogs-Policy"
  statement {
    sid    = "AllowALBAccountAccessToAccessLogsBucket"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.current.arn]
    }
    actions = ["s3:PutObject"]
    resources = [
      aws_s3_bucket.access_logs.arn,
      local.elb_account_permissions
    ]
  }

  statement {
    sid    = "AWS-Log-Delivery-Write"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions = ["s3:PutObject"]
    #resources = ["${aws_s3_bucket.s3_access_logs.arn}/${var.workspace_in}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    resources = [local.elb_account_permissions]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid    = "AWS-Log-Delivery-Acl-Check"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.access_logs.arn]
  }
}

data "aws_iam_policy_document" "access_logs" {
  source_policy_documents = [
    data.aws_iam_policy_document.access_logs_https.json,
    data.aws_iam_policy_document.access_logs_loadbalancer.json
  ]
}