output "iot_thing_name" {
  description = "The name of the created IoT Thing."
  value       = aws_iot_thing.pi_node.name
}

output "iot_certificate_arn" {
  description = "The ARN of the created IoT certificate."
  value       = aws_iot_certificate.pi_node_cert.arn
}

output "iot_certificate_pem" {
  description = "The PEM encoded IoT certificate."
  value       = aws_iot_certificate.pi_node_cert.certificate_pem
  sensitive   = true # Mark as sensitive!
}

output "iot_private_key_pem" {
  description = "The PEM encoded IoT private key."
  value       = aws_iot_certificate.pi_node_cert.private_key
  sensitive   = true # Mark as sensitive!
}

output "iot_role_alias_name" {
  description = "The name of the created IoT Role Alias."
  value       = aws_iot_role_alias.pi_node_role_alias.alias
}

output "iot_assumed_role_arn" {
  description = "The ARN of the IAM role assumed by the Pi node."
  value       = aws_iam_role.pi_node_assumed_role.arn
}

output "iot_credentials_endpoint" {
  description = "The AWS IoT Core Credentials Endpoint."
  value       = data.aws_iot_endpoint.credentials.endpoint_address
}

output "submission_queue_urls" {
  description = "Map of SQS Submission Queue URLs by network."
  value = {
    for network in var.networks :
    network => aws_sqs_queue.submission_queue[network].id
  }
}

output "submission_status_table_name" {
  description = "Name of the DynamoDB Submission Status table."
  value       = aws_dynamodb_table.submission_status.name
}

output "configured_networks" {
  description = "List of Bitcoin networks configured for this environment."
  value       = var.networks
}

output "cloudfront_distribution_domain_name" {
  description = "The domain name of the CloudFront distribution."
  value       = aws_cloudfront_distribution.template_distribution.domain_name
}
