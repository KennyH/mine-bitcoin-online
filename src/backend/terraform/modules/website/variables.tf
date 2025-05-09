variable "environment" {
  description = "Environment name (dev/int/prod)"
  type        = string
}

variable "domain_name" {
  description = "custom domain name for site"
  type        = string
}

variable "turnstile_secret_key" {
  description = "Cloudflare secret key for turnstile"
  type = string
  sensitive   = true
}

variable "aws_route53_zone_name" {
  description = "custom domain name for site"
  type        = string
  default     = "bitcoinbrowserminer.com" # must own this domain
}

variable "aws_region" {
  description = "aws region for site and services"
  type    = string
  default = "us-west-2"
}

variable "project_name" {
  description = "project name for tagging resources"
  type        = string
  default     = "MineBitcoinOnline"
}

variable "turnstile_api_burst_limit" {
  description = "The throttling burst limit for the Turnstile verification API Gateway stage."
  type        = number
  default     = 10
}

variable "turnstile_api_rate_limit" {
  description = "The throttling rate limit (requests per second) for the Turnstile verification API Gateway stage."
  type        = number
  default     = 5
}
