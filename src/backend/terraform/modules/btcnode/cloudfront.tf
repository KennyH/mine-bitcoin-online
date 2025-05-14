resource "aws_cloudfront_origin_access_control" "template_bucket_oac" {
  name                              = "${var.environment}-${var.template_bucket_name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "no-override"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "template_distribution" {
  origin {
    domain_name = aws_s3_bucket.template_bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.template_bucket.id

    origin_access_control_id = aws_cloudfront_origin_access_control.template_bucket_oac.id
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.template_bucket.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 60
    default_ttl            = 300 # 5 minutes
    max_ttl                = 86400 # 1 day
  }

  # Maybe later add specific cache behaviors for /mainnet/, /testnet/, /regtest/ prefixes
  # dynamic "ordered_cache_behavior" {
  #   for_each = var.networks
  #   content {
  #     path_pattern     = "/${ordered_cache_behavior.value}/*"
  #     allowed_methods  = ["GET", "HEAD", "OPTIONS"]
  #     cached_methods   = ["GET", "HEAD"]
  #     target_origin_id = aws_s3_bucket.template_bucket.id
  #     forwarded_values {
  #       query_string = false
  #       cookies {
  #         forward = "none"
  #       }
  #     }
  #     viewer_protocol_policy = "allow-all"
  #     min_ttl                = 0
  #     default_ttl            = 60 # Shorter TTL for template data?
  #     max_ttl                = 300
  #   }
  # }


  restrictions {
    geo_restriction {
      restriction_type = "none" # Or restrict as needed
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    # maybe use custom domain later...
    # acm_certificate_arn = "arn:aws:acm:us-east-1:ACCOUNT_ID:certificate/CERTIFICATE_ID"
    # ssl_support_method             = "sni-only"
    # minimum_protocol_version       = "TLSv1.2_2021"
  }

  comment = "CloudFront distribution for ${var.environment} block templates"

  tags = {
    Environment = var.environment
    Project     = "BitcoinBrowserMiner"
  }
}