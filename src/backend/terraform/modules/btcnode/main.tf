data "aws_iot_endpoint" "credentials" {
  endpoint_type = "CREDENTIALS"
}

data "aws_caller_identity" "current" {}