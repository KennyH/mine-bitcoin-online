output "prod_cloudfront_distribution_url" {
  description = "CloudFront distribution domain name for the website for Prod"
  value       = module.website.cloudfront_distribution_url
}

output "prod_cf_turnstile_api_endpoint" {
  description = "The invoke URL for the Cloudflare Turnstile verification API endpoint for Prod"
  value       = module.website.cf_turnstile_api_endpoint
}

output "prod_iot_certificate_pem" {
  description = "PEM encoded certificate for the Prod IoT Thing"
  value       = module.btcnode.iot_certificate_pem
  sensitive   = true
}

output "prod_iot_private_key_pem" {
  description = "PEM encoded private key for the Prod IoT Thing"
  value       = module.btcnode.iot_private_key_pem
  sensitive   = true
}

output "prod_iot_credentials_endpoint" {
  description = "AWS IoT Core Credentials Endpoint for Prod"
  value       = module.btcnode.iot_credentials_endpoint
}

output "prod_iot_role_alias_name" {
  description = "IoT Role Alias Name for Prod"
  value       = module.btcnode.iot_role_alias_name
}

output "prod_iot_thing_name" {
  description = "IoT Thing Name for Prod"
  value       = module.btcnode.iot_thing_name
}
