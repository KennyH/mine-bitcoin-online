# Cognito User Pool
resource "aws_cognito_user_pool" "user_pool" {
  name = "minebitcoinonline-user-pool-${var.environment}"

  mfa_configuration = "ON"

  software_token_mfa_configuration {
    enabled = true
  }

  auto_verified_attributes = ["email"]

  username_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_uppercase = true
    require_symbols   = true
  }

  schema {
    name                     = "email"
    required                 = true
    mutable                  = false
    attribute_data_type      = "String"
    string_attribute_constraints {
      min_length = 5
      max_length = 254
    }
  }

  schema {
    name                = "tos_accepted"
    attribute_data_type = "Boolean"
    required            = true
    mutable             = false
  }
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "user_pool_client" {
  name                         = "minebitcoinonline-user-pool-client-${var.environment}"
  user_pool_id                 = aws_cognito_user_pool.user_pool.id
  generate_secret              = false
  allowed_oauth_flows_user_pool_client = true

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  supported_identity_providers = ["COGNITO"]

  allowed_oauth_flows = ["code", "implicit"]

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