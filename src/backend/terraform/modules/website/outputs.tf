output "cloudfront_distribution_url" {
  description = "CloudFront distribution domain name for the website"
  value       = aws_cloudfront_distribution.frontend_distribution.domain_name
}

output "cf_turnstile_api_endpoint" {
  description = "The invoke URL for the Cloudflare Turnstile verification API endpoint"
  value       = "${aws_apigatewayv2_stage.cf_turnstile_default_stage.invoke_url}/verify"
}
