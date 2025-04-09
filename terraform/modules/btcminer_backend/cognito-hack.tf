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
    }
  }
}
STACK

  depends_on = [aws_cognito_user_pool.user_pool]
}
