resource "aws_s3_bucket" "www" {
  bucket = "${var.bucket_name}"

  logging {
    target_bucket = "${aws_s3_bucket.log_bucket.id}"
    target_prefix = "logs/"
  }

  acl = "public-read"

  website {
    index_document = "index.html"
    error_document = "404.html"
  }
}

resource "aws_s3_bucket_policy" "www" {
  bucket = "${aws_s3_bucket.www.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "grahamsfancybucketpolicy",
  "Statement": [
    {
      "Sid": "AddPerm",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource":["arn:aws:s3:::${var.bucket_name}/*"]
    }
  ]
}
POLICY
}

resource "aws_s3_bucket" "301" {
  bucket = "${var.301_name}"
  acl = "public-read"
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
      "Resource":["arn:aws:s3:::${var.301_name}/*"]
    }
  ]
}
POLICY
}

resource "aws_s3_bucket" "log_bucket" {
  bucket = "grahamgilbert-logs"
}