variable "environment" {
  description = "Environment name (dev/int/prod)"
  type        = string
}

variable "domain_name" {
  description = "custom domain name for site"
  type        = string
}

variable "aws_region" {
  description = "aws region for site and services"
  type    = string
  default = "us-west-2"
}