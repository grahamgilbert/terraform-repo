resource "aws_s3_bucket" "www" {
  bucket = "${var.bucket_name}"

  logging {
    target_bucket = "${aws_s3_bucket.log_bucket.id}"
    target_prefix = "logs/"
  }

  acl = "private"
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.www.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["${aws_s3_bucket.www.arn}"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"]
    }
  }
}

resource "aws_s3_bucket_policy" "www" {
  bucket = "${aws_s3_bucket.www.id}"
  policy = "${data.aws_iam_policy_document.s3_policy.json}"
}

resource "aws_s3_bucket" "three_oh_one" {
  bucket = "${var.three_oh_one_name}"
  acl    = "public-read"

  website {
    redirect_all_requests_to = "https://${var.root_domain_name}"
  }
}

resource "aws_s3_bucket_policy" "301" {
  bucket = "${aws_s3_bucket.301.id}"

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
  bucket = "grahamgilbert-logs"

  lifecycle_rule {
    enabled = true

    transition {
      days          = "30"
      storage_class = "STANDARD_IA"
    }
  }
}
