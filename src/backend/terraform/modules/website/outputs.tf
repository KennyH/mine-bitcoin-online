output "cloudfront_distribution_url" {
  description = "CloudFront distribution domain name for the website"
  value       = aws_cloudfront_distribution.frontend_distribution.domain_name
}