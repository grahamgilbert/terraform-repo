locals {
  gilbertworks_domain_name = "gilbertworks.co"
}

resource "aws_route53_zone" "gilbertworks" {
  name = local.gilbertworks_domain_name
}

resource "aws_s3_bucket" "gilbertworks" {
  bucket        = local.gilbertworks_domain_name
  acl           = "private"
  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket" "gilbertworks_www_redirect" {
  bucket        = "www.${local.gilbertworks_domain_name}"
  acl           = "public-read"
  force_destroy = true

  website {
    redirect_all_requests_to = "https://${local.gilbertworks_domain_name}"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_policy" "gilbertworks_www_redirect" {
  bucket = aws_s3_bucket.gilbertworks_www_redirect.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "${aws_s3_bucket.gilbertworks_www_redirect.arn}/*"
    }
  ]
}
POLICY
}

resource "aws_cloudfront_origin_access_identity" "gilbertworks" {
  comment = local.gilbertworks_domain_name
}

data "aws_iam_policy_document" "gilbertworks_bucket" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.gilbertworks.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.gilbertworks.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.gilbertworks.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.gilbertworks.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "gilbertworks" {
  bucket = aws_s3_bucket.gilbertworks.id
  policy = data.aws_iam_policy_document.gilbertworks_bucket.json
}

resource "aws_acm_certificate" "gilbertworks" {
  domain_name               = local.gilbertworks_domain_name
  validation_method         = "DNS"
  subject_alternative_names = ["www.${local.gilbertworks_domain_name}"]
}

resource "aws_route53_record" "gilbertworks_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.gilbertworks.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.gilbertworks.zone_id
}

resource "aws_acm_certificate_validation" "gilbertworks" {
  certificate_arn         = aws_acm_certificate.gilbertworks.arn
  validation_record_fqdns = [for record in aws_route53_record.gilbertworks_cert_validation : record.fqdn]
}

resource "aws_cloudfront_distribution" "gilbertworks" {
  origin {
    domain_name = aws_s3_bucket.gilbertworks.bucket_regional_domain_name
    origin_id   = local.gilbertworks_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.gilbertworks.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.gilbertworks_domain_name
    min_ttl                = 0
    default_ttl            = 1800
    max_ttl                = 3600

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  aliases = [local.gilbertworks_domain_name]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.gilbertworks.certificate_arn
    ssl_support_method  = "sni-only"
  }
}

resource "aws_cloudfront_distribution" "gilbertworks_www_redirect" {
  origin {
    domain_name = aws_s3_bucket.gilbertworks_www_redirect.website_endpoint
    origin_id   = "www.${local.gilbertworks_domain_name}"

    custom_origin_config {
      origin_protocol_policy = "http-only"
      http_port              = "80"
      https_port             = "443"
      origin_ssl_protocols   = ["TLSv1"]
    }
  }

  enabled     = true
  price_class = "PriceClass_100"

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "www.${local.gilbertworks_domain_name}"
    min_ttl                = 0
    default_ttl            = 1800
    max_ttl                = 3600

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }
  }

  aliases = ["www.${local.gilbertworks_domain_name}"]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.gilbertworks.certificate_arn
    ssl_support_method  = "sni-only"
  }
}

resource "aws_route53_record" "gilbertworks_root" {
  zone_id = aws_route53_zone.gilbertworks.zone_id
  type    = "A"
  name    = local.gilbertworks_domain_name

  alias {
    name                   = aws_cloudfront_distribution.gilbertworks.domain_name
    zone_id                = aws_cloudfront_distribution.gilbertworks.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "gilbertworks_www" {
  zone_id = aws_route53_zone.gilbertworks.zone_id
  type    = "A"
  name    = "www.${local.gilbertworks_domain_name}"

  alias {
    name                   = aws_cloudfront_distribution.gilbertworks_www_redirect.domain_name
    zone_id                = aws_cloudfront_distribution.gilbertworks_www_redirect.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "gilbertworks_mx" {
  zone_id = aws_route53_zone.gilbertworks.zone_id
  type    = "MX"
  name    = local.gilbertworks_domain_name
  ttl     = 300

  records = [
    "60 aspmx4.googlemail.com",
    "10 aspmx.l.google.com",
    "50 aspmx3.googlemail.com",
    "20 alt2.aspmx.l.google.com",
    "40 aspmx2.googlemail.com",
    "30 alt1.aspmx.l.google.com",
  ]
}
