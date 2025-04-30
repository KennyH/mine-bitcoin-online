resource "aws_iam_role" "cognito_custom_auth_lambda_role" {
  name               = "${var.environment}-mine-bitcoin-online-cognito-custom-auth-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

data "aws_iam_policy_document" "lambda_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "cognito_custom_auth_lambda_attach" {
  role       = aws_iam_role.cognito_custom_auth_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "cognito_custom_auth_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/cognito_custom_auth_lambda.py"
  output_path = "${path.module}/cognito_custom_auth_lambda.zip"
}

resource "aws_lambda_function" "cognito_custom_auth_lambda" {
  function_name = "${var.environment}-mine-bitcoin-online-cognito-custom-auth-lambda"
  role          = aws_iam_role.cognito_custom_auth_lambda_role.arn
  handler       = "cognito_custom_auth_lambda.lambda_handler"
  runtime       = "python3.11"
  filename      = data.archive_file.cognito_custom_auth_lambda_zip.output_path

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }
}

resource "aws_iam_role_policy" "lambda_ses_send" {
  name = "lambda-ses-send"
  role = aws_iam_role.cognito_custom_auth_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_permission" "cognito_custom_auth_lambda" {
  statement_id  = "AllowExecutionFromCognito"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cognito_custom_auth_lambda.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.user_pool.arn
}