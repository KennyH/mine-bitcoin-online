output "cloudfront_distribution_url" {
  description = "CloudFront distribution domain name for the website"
  value       = aws_cloudfront_distribution.frontend_distribution.domain_name
}

output "cf_turnstile_api_endpoint" {
  description = "The invoke URL for the Cloudflare Turnstile verification API endpoint"
  value       = "${aws_apigatewayv2_stage.cf_turnstile_default_stage.invoke_url}/verify"
}

output "appconfig_application_id" {
  description = "The ID of the AppConfig application."
  value       = aws_appconfig_application.feature_flags_app.id
}

output "appconfig_environment_id" {
  description = "The ID of the AppConfig environment."
  value       = aws_appconfig_environment.feature_flags_env.environment_id
}

output "appconfig_configuration_profile_id" {
  description = "The ID of the AppConfig configuration profile."
  value       = aws_appconfig_configuration_profile.feature_flags_profile.configuration_profile_id
}
