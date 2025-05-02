resource "aws_iam_role" "cf_turnstile_lambda_role" {
  name = "${var.environment}-cf-turnstile-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

resource "aws_iam_role_policy_attachment" "cf_turnstile_lambda_attach" {
  role       = aws_iam_role.cf_turnstile_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "cf_turnstile_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/cf_turnstile_lambda.py"
  output_path = "${path.module}/lambda_cf_turnstile.zip"
}

resource "aws_lambda_function" "cf_turnstile_lambda" {
  function_name = "${var.environment}-cf-turnstile-lambda"
  role          = aws_iam_role.cf_turnstile_lambda_role.arn
  handler       = "cf_turnstile_lambda.lambda_handler"
  runtime       = "python3.11"

  filename         = data.archive_file.cf_turnstile_lambda_zip.output_path
  source_code_hash = data.archive_file.cf_turnstile_lambda_zip.output_base64sha256

  environment {
    variables = {
      ENVIRONMENT            = var.environment
      LOG_LEVEL              = var.environment == "prod" ? "ERROR" : "INFO"
      TURNSTILE_SECRET_KEY = var.turnstile_secret_key
    }
  }

  timeout = 10

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_log_group" "cf_turnstile_lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.cf_turnstile_lambda.function_name}"
  retention_in_days = 7

  lifecycle {
    prevent_destroy = false
  }

  depends_on = [aws_lambda_function.cf_turnstile_lambda]
}

