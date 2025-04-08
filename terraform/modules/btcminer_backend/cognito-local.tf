resource "aws_cognito_user_pool_client" "user_pool_client_local_dev" {
  count                                = var.environment == "dev" ? 1 : 0
  name                                 = "minebitcoinonline-user-pool-client-local-dev"
  user_pool_id                         = aws_cognito_user_pool.user_pool.id
  generate_secret                      = false
  allowed_oauth_flows_user_pool_client = true

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  supported_identity_providers = ["COGNITO"]

  allowed_oauth_flows = ["code"]

  allowed_oauth_scopes = [
    "email",
    "openid",
    "profile"
  ]

  callback_urls = ["http://localhost:3000"]
  logout_urls   = ["http://localhost:3000"]

  prevent_user_existence_errors = "ENABLED"
}