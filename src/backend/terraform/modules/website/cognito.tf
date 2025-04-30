# Cognito User Pool with Passwordless Email OTP
resource "aws_cognito_user_pool" "user_pool" {
  name = "minebitcoinonline-user-pool-${var.environment}"

  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]
  mfa_configuration        = "OFF"

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
    required            = false
    mutable             = false
  }

  deletion_protection = var.environment == "prod" ? "ACTIVE" : "INACTIVE"

  lambda_config {
    pre_sign_up                    = aws_lambda_function.cognito_custom_auth_lambda.arn
    define_auth_challenge          = aws_lambda_function.cognito_custom_auth_lambda.arn
    create_auth_challenge          = aws_lambda_function.cognito_custom_auth_lambda.arn
    verify_auth_challenge_response = aws_lambda_function.cognito_custom_auth_lambda.arn
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  device_configuration {
    challenge_required_on_new_device      = false
    device_only_remembered_on_user_prompt = false
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # using a fake random number password, so need a minimum policy
  password_policy {
    minimum_length    = 6
    require_uppercase = false
    require_lowercase = false
    require_numbers   = false
    require_symbols   = false
    temporary_password_validity_days = 1
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"

    email_subject = "Your Bitcoin Browser Miner Login Code"

    email_message = <<-EOM
      Your verification code is: {####}

      Use this code to log in to https://${var.domain_name}.

      If you did not request this code, please ignore this email.
    EOM
  }
}


# Cognito User Pool Client (Passwordless)
resource "aws_cognito_user_pool_client" "user_pool_client" {
  name                 = "minebitcoinonline-user-pool-client-${var.environment}"
  user_pool_id         = aws_cognito_user_pool.user_pool.id
  generate_secret      = false

  explicit_auth_flows = [
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  supported_identity_providers         = ["COGNITO"]
  prevent_user_existence_errors        = "ENABLED"
  allowed_oauth_flows_user_pool_client = false

  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}

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
