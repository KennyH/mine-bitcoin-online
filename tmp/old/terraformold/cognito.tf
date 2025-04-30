# Cognito User Pool
resource "aws_cognito_user_pool" "user_pool" {
  name = "minebitcoinonline-user-pool-${var.environment}"

  mfa_configuration = "OFF"

#   software_token_mfa_configuration {
#     enabled = true
#   }

  device_configuration {
    device_only_remembered_on_user_prompt = false
    challenge_required_on_new_device      = false
  }

  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]

  # sign_in_policy {
  #   allowed_first_auth_factors = ["EMAIL_OTP"]
  # }

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = false
    string_attribute_constraints {
      min_length = 5
      max_length = 254
    }
  }

  schema {
    name                = "name"
    attribute_data_type = "String"
    required            = false
    mutable             = true
    string_attribute_constraints {
      min_length = 1
      max_length = 128
    }
  }

  schema {
    name                = "tos_accepted"
    attribute_data_type = "Boolean"
    required            = false # need to have UI enforce this..
    mutable             = false
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  deletion_protection = var.environment == "prod" ? "ACTIVE" : "INACTIVE"

}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "user_pool_client" {
  name                         = "minebitcoinonline-user-pool-client-${var.environment}"
  user_pool_id                 = aws_cognito_user_pool.user_pool.id
  generate_secret              = false # The frontend site should never have a client secret because it is public.
  
  allowed_oauth_flows_user_pool_client = true

  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  supported_identity_providers = ["COGNITO"]

  allowed_oauth_flows = ["code"]

  allowed_oauth_scopes = [
    "email",
    "openid",
    "profile"
  ]

  callback_urls = ["https://${var.domain_name}"]
  logout_urls   = ["https://${var.domain_name}"]

  prevent_user_existence_errors = "ENABLED"
}

# Cognito User Pool Domain
resource "aws_cognito_user_pool_domain" "user_pool_domain" {
  domain       = "${var.environment}-bitcoin-miner-auth"
  user_pool_id = aws_cognito_user_pool.user_pool.id
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.user_pool.id
}

output "cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.user_pool_client.id
}

output "cognito_domain_url" {
  value = "https://${aws_cognito_user_pool_domain.user_pool_domain.domain}.auth.${var.aws_region}.amazoncognito.com"
}