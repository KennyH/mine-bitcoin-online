# https://github.com/tenable/terrascan/blob/master/docs/policies/aws.md

#ts:skip=AC_AWS_0032 Ensure CloudFront has WAF enabled (cost issue)
#ts:skip=AC_AWS_0026 Ensure geo restriction is enabled (business decision)
#ts:skip=AC_AWS_0025 Ensure logging is enabled (cost issue)
resource "aws_cloudfront_distribution" "frontend_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.frontend_bucket.bucket}.s3-website-${var.aws_region}.amazonaws.com"
    origin_id   = aws_s3_bucket.frontend_bucket.id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
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

    # # TODO: Get back to this when closer to launching prod, as it will help with security XSS stuff.
    # response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers_policy.id
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

# # TODO: Get back to this when closer to launching prod, as it will help with security XSS stuff.
# resource "aws_cloudfront_response_headers_policy" "security_headers_policy" {
#   name    = "FrontendSecurityHeadersPolicy-${var.environment}-minebitcoinonline"
#   comment = "Security headers for the frontend CloudFront distribution"

#   security_headers_config {
#     content_security_policy {
#       content_security_policy = <<-EOT
#         default-src 'self';
#         script-src 'self' 'unsafe-eval' https://challenges.cloudflare.com; # Adjust unsafe-eval, include Cloudflare for Turnstile
#         style-src 'self' 'unsafe-inline'; # Adjust unsafe-inline
#         img-src 'self' data: https://*;
#         connect-src 'self' https://*.amazoncognito.com https://challenges.cloudflare.com ${aws_apigatewayv2_stage.cf_turnstile_default_stage.invoke_url};
#         font-src 'self';
#         object-src 'none';
#         base-uri 'self';
#         form-action 'self';
#         frame-ancestors 'none'; # Prevent framing
#         upgrade-insecure-requests; # Forces HTTPS
#         block-all-mixed-content; # Prevents mixed content
#         report-uri ${var.csp_report_uri}; # Optional
#       EOT
#       override = true
#     }

#     xss_protection {
#       mode     = true
#       protection = true # Enable protection
#       block    = true   # Block mode
#       override = true
#     }

#     content_type_options {
#       nosniff = true # Prevents MIME sniffing
#       override = true
#     }

#     frame_options {
#       frame_option = "DENY" # Prevents clickjacking (DENY is stronger than SAMEORIGIN)
#       override = true
#     }

#     referrer_policy {
#       referrer_policy = "strict-origin-when-cross-origin"
#       override = true
#     }

#     strict_transport_security {
#       include_subdomains = true
#       override           = true
#       preload            = true
#       access_control_max_age_sec = 31536000 # 1 year
#     }
#   }
# }
