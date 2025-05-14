data "aws_iot_endpoint" "credentials" {
  endpoint_type = "iot:CredentialProvider"
}

data "aws_caller_identity" "current" {}