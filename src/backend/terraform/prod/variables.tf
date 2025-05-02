variable "environment" {
  type = string
}

variable "domain_name" {
  type    = string
}

variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "turnstile_secret_key" {
  type = string
  sensitive   = true
}
