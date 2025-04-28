resource "aws_cloudfront_origin_access_identity" "origin_identity" {
  comment = "OAI for mine-bitcoin-online-frontend-${var.environment}"
}

#new
resource "aws_cloudfront_origin_access_control" "frontend_oac" {
  name                              = "frontend-oac-${var.environment}"
  description                       = "OAC for mine-bitcoin-online-frontend-${var.environment}"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
  origin_access_control_origin_type = "s3"
}

# https://github.com/tenable/terrascan/blob/master/docs/policies/aws.md

#ts:skip=AC_AWS_0032 Ensure CloudFront has WAF enabled (cost issue)
#ts:skip=AC_AWS_0026 Ensure geo restriction is enabled (business decision)
#ts:skip=AC_AWS_0025 Ensure logging is enabled (cost issue)
resource "aws_cloudfront_distribution" "frontend_distribution" {
  origin {
    domain_name = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.frontend_bucket.id

    # s3_origin_config {
    #   origin_access_identity = aws_cloudfront_origin_access_identity.origin_identity.cloudfront_access_identity_path
    # }

    #new
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
    #can't do this with s3 webhost :`(
    #origin_access_control_id = aws_cloudfront_origin_access_control.frontend_oac.id
  }

  enabled             = true
  default_root_object = "index.html"

  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/404.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 404
    response_page_path = "/404.html"
  }

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
    min_ttl     = 300     # 5 minutes
    default_ttl = 3600    # 1 hour
    max_ttl     = 86400   # 1 day

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.redirect_and_add_index_html.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.domain_name == "" ? true : false
    acm_certificate_arn            = length(aws_acm_certificate.cert) > 0 ? aws_acm_certificate.cert[0].arn : null
    ssl_support_method             = length(aws_acm_certificate.cert) > 0 ? "sni-only" : null
    minimum_protocol_version       = length(aws_acm_certificate.cert) > 0 ? "TLSv1.2_2021" : "TLSv1"
  }

  aliases = var.domain_name != "" ? [var.domain_name] : []
  comment = var.domain_name != "" ? "${var.environment} env for bitcoin browser miner site" : null

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_acm_certificate" "cert" {
  provider          = aws.acm
  count             = var.domain_name != "" ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"
}
