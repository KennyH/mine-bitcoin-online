resource "aws_cloudfront_origin_access_identity" "origin_identity" {
  comment = "OAI for mine-bitcoin-online-frontend-${var.environment}"
}

resource "aws_cloudfront_distribution" "frontend_distribution" {
  #ts:skip=AC_AWS_0493 Ensure CloudFront has WAF enabled (cost issue)
  #ts:skip=AC_AWS_0486 Ensure geo restriction is enabled (business decision)
  #ts:skip=AC_AWS_0487 Ensure logging is enabled (cost issue)
  origin {
    domain_name = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.frontend_bucket.id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.frontend_bucket.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.domain_name == "" ? true : false
    acm_certificate_arn            = var.domain_name != "" ? aws_acm_certificate.cert[0].arn : null
    ssl_support_method             = var.domain_name != "" ? "sni-only" : null
    minimum_protocol_version       = var.domain_name != "" ? "TLSv1.2_2021" : "TLSv1"
  }

  aliases = var.domain_name != "" ? [var.domain_name] : []

  comment = var.domain_name != "" ? "${var.environment} env for bitcoin browser miner site" : null

  tags = {
    Environment = var.environment
    Project     = "MineBitcoinOnline"
  }
}

resource "aws_acm_certificate" "cert" {
  count             = var.domain_name != "" ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"
}
