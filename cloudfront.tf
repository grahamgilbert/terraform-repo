resource "aws_cloudfront_distribution" "www_distribution" {
  origin {
    // Here we're using our S3 bucket's URL!
    domain_name = aws_s3_bucket.www.bucket_regional_domain_name

    // This can be any name to identify this origin.
    origin_id = "${var.root_domain_name}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path}"
    }
  }

  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  // All values are defaults from the AWS console.
  default_cache_behavior {
    lambda_function_association {
      event_type = "origin-request"
      lambda_arn = "${aws_lambda_function.redirect_lambda.arn}:${aws_lambda_function.redirect_lambda.version}"
    }

    # lambda_function_association {
    #   event_type = "origin-response"
    #   lambda_arn = "${aws_lambda_function.hsts_lambda.arn}:${aws_lambda_function.hsts_lambda.version}"
    # }

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    // This needs to match the `origin_id` above.
    target_origin_id = "${var.root_domain_name}"
    min_ttl          = 0
    default_ttl      = 1800
    max_ttl          = 3600

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  aliases = ["${var.root_domain_name}"]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = "${aws_acm_certificate_validation.cert.certificate_arn}"
    ssl_support_method  = "sni-only"
  }
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Some comment"
}


