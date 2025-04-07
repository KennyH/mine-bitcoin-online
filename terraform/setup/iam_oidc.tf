provider "aws" {
  region = "us-west-2"
}

data "tls_certificate" "github_oidc_cert" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

# resource "aws_iam_openid_connect_provider" "github_oidc" {
#   url = "https://token.actions.githubusercontent.com"
#   client_id_list = ["sts.amazonaws.com"]
#   thumbprint_list = [data.tls_certificate.github_oidc_cert.certificates[0].sha1_fingerprint]
# }

data "aws_iam_openid_connect_provider" "github_oidc" {
  url = "https://token.actions.githubusercontent.com"
}

