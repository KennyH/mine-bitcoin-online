output "cloudfront_distribution_url" {
  description = "CloudFront distribution domain name for ${var.project_name}"
  value       = aws_cloudfront_distribution.frontend_distribution.domain_name
}