resource "aws_cloudformation_stack" "cognito_user_pool_override" {
  name = "CognitoUserPoolOverride-${var.environment}"

  template_body = <<STACK
{
  "Resources": {
    "UserPoolOverride": {
      "Type": "AWS::Cognito::UserPool",
      "Properties": {
        "UserPoolName": "${aws_cognito_user_pool.user_pool.name}",
        "Policies": {
          "SignInPolicy": {
            "AllowedFirstAuthFactors": ["EMAIL_OTP"]
          }
        },
        "UsernameAttributes": ["email"],
        "AutoVerifiedAttributes": ["email"]
      }
    },
    "UserPoolClientOverrideCloud": {
      "Type": "AWS::Cognito::UserPoolClient",
      "Properties": {
        "ClientName": "${aws_cognito_user_pool_client.user_pool_client.name}",
        "UserPoolId": "${aws_cognito_user_pool.user_pool.id}",
        "ExplicitAuthFlows": ["ALLOW_REFRESH_TOKEN_AUTH"],
        "SupportedIdentityProviders": ["COGNITO"],
        "AllowedOAuthFlowsUserPoolClient": true,
        "AllowedOAuthFlows": ["code"],
        "AllowedOAuthScopes": ["email", "openid", "profile"],
        "CallbackURLs": ["https://${var.domain_name}"],
        "LogoutURLs": ["https://${var.domain_name}"],
        "PreventUserExistenceErrors": "ENABLED"
      }
    }%{ if var.environment == "dev" },
    "UserPoolClientOverrideLocalDev": {
      "Type": "AWS::Cognito::UserPoolClient",
      "Properties": {
        "ClientName": "${aws_cognito_user_pool_client.user_pool_client_local_dev[0].name}",
        "UserPoolId": "${aws_cognito_user_pool.user_pool.id}",
        "ExplicitAuthFlows": ["ALLOW_REFRESH_TOKEN_AUTH"],
        "SupportedIdentityProviders": ["COGNITO"],
        "AllowedOAuthFlowsUserPoolClient": true,
        "AllowedOAuthFlows": ["code"],
        "AllowedOAuthScopes": ["email", "openid", "profile"],
        "CallbackURLs": ["http://localhost:3000"],
        "LogoutURLs": ["http://localhost:3000"],
        "PreventUserExistenceErrors": "ENABLED"
      }
    }%{ endif }
  }
}
STACK

  depends_on = [
    aws_cognito_user_pool.user_pool,
    aws_cognito_user_pool_client.user_pool_client,
    aws_cognito_user_pool_client.user_pool_client_local_dev
  ]
}
