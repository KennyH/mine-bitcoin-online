variable "environment" {
  description = "Environment name (dev/int/prod)"
  type        = string
}

variable "domain_name" {
  description = "TODO make custom domain name"
  type        = string
  default     = ""
}