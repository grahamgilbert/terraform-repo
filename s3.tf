resource "aws_s3_bucket" "www" {
  bucket = var.bucket_name

  logging {
    target_bucket = aws_s3_bucket.log_bucket.id
    target_prefix = "logs/"
  }

  website {
    index_document = "index.html"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  acl           = "private"
  force_destroy = true
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.www.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.www.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "www" {
  bucket = aws_s3_bucket.www.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

resource "aws_s3_bucket" "three_oh_one" {
  bucket        = var.three_oh_one_name
  acl           = "public-read"
  force_destroy = true

  website {
    redirect_all_requests_to = "https://${var.root_domain_name}"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_policy" "three_oh_one" {
  bucket = aws_s3_bucket.three_oh_one.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "grahamsfancy301policy",
  "Statement": [
    {
      "Sid": "AddPerm",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource":["arn:aws:s3:::${var.three_oh_one_name}/*"]
    }
  ]
}
POLICY
}

resource "aws_s3_bucket" "log_bucket" {
  bucket        = "grahamgilbert-logs"
  acl           = "log-delivery-write"
  force_destroy = true

  lifecycle_rule {
    enabled = true

    expiration {
      days = 120
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

data "aws_iam_policy_document" "ggcom_policydoc" {
  statement {
    actions = ["s3:*"]
    resources = [
      "${aws_s3_bucket.www.arn}/*",
      aws_s3_bucket.www.arn,
      "${aws_s3_bucket.gilbertworks.arn}/*",
      aws_s3_bucket.gilbertworks.arn,
    ]
    effect = "Allow"
  }

  statement {
    actions = ["cloudfront:CreateInvalidation"]
    resources = [
      aws_cloudfront_distribution.www_distribution.arn,
      aws_cloudfront_distribution.gilbertworks.arn,
      aws_cloudfront_distribution.gilbertworks_www_redirect.arn,
    ]
    effect = "Allow"
  }
}

resource "aws_iam_user" "www_deploy_user" {
  name = "www_deploy_user"
}

resource "aws_iam_user_policy" "www_deploy_user_policy" {
  name   = aws_iam_user.www_deploy_user.name
  user   = aws_iam_user.www_deploy_user.name
  policy = join("", data.aws_iam_policy_document.ggcom_policydoc.*.json)
}
