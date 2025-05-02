output "cloudfront_distribution_url" {
  description = "CloudFront distribution domain name for the website"
  value       = module.website.cloudfront_distribution_url
}

output "cf_turnstile_api_endpoint" {
  description = "The invoke URL for the Cloudflare Turnstile verification API endpoint"
  value       = module.website.cf_turnstile_api_endpoint
}
