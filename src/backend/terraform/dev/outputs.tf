output "dev_cloudfront_distribution_url" {
  description = "CloudFront distribution domain name for the website for Dev"
  value       = module.website.cloudfront_distribution_url
}

output "dev_cf_turnstile_api_endpoint" {
  description = "The invoke URL for the Cloudflare Turnstile verification API endpoint for Dev"
  value       = module.website.cf_turnstile_api_endpoint
}

output "dev_iot_certificate_pem" {
  description = "PEM encoded certificate for the Dev IoT Thing"
  value       = module.btcnode.iot_certificate_pem
  sensitive   = true
}

output "dev_iot_private_key_pem" {
  description = "PEM encoded private key for the Dev IoT Thing"
  value       = module.btcnode.iot_private_key_pem
  sensitive   = true
}

output "dev_iot_credentials_endpoint" {
  description = "AWS IoT Core Credentials Endpoint for Dev"
  value       = module.btcnode.iot_credentials_endpoint
}

output "dev_iot_role_alias_name" {
  description = "IoT Role Alias Name for Dev"
  value       = module.btcnode.iot_role_alias_name
}

output "dev_iot_thing_name" {
  description = "IoT Thing Name for Dev"
  value       = module.btcnode.iot_thing_name
}
