variable "environment" {
  description = "Environment name (dev/int/prod)"
  type        = string
}

variable "domain_name" {
  description = "custom domain name for site"
  type        = string
}

variable "aws_region" {
  type = string
}