resource "aws_apigatewayv2_api" "cf_turnstile_api" {
  name          = "${var.environment}-mine-bitcoin-online-cf-turnstile-api"
  protocol_type = "HTTP"
  description   = "API Gateway for Cloudflare Turnstile verification"

  # TODO get this from variables
  cors_configuration {
    allow_origins = var.environment == "dev" ? [
      "https://dev-env.bitcoinbrowserminer.com",
      "http://localhost:3000" # Might also need http://127.0.0.1:3000
      ] : [
      "https://bitcoinbrowserminer.com"
    ]
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
    max_age       = 300
  }
}

resource "aws_apigatewayv2_integration" "cf_turnstile_lambda_integration" {
  api_id           = aws_apigatewayv2_api.cf_turnstile_api.id
  integration_type = "AWS_PROXY"
  integration_uri        = aws_lambda_function.cf_turnstile_lambda.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "cf_turnstile_verify_route" {
  api_id    = aws_apigatewayv2_api.cf_turnstile_api.id
  route_key = "POST /verify"
  target    = "integrations/${aws_apigatewayv2_integration.cf_turnstile_lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "cf_turnstile_root_route" {
  api_id    = aws_apigatewayv2_api.cf_turnstile_api.id
  route_key = "POST /{proxy+}"  # greedy... catch everything
  target    = "integrations/${aws_apigatewayv2_integration.cf_turnstile_lambda_integration.id}"
}

resource "aws_lambda_permission" "api_gateway_invoke_cf_turnstile_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cf_turnstile_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # Allow ANY method / ANY route
  source_arn = "${aws_apigatewayv2_api.cf_turnstile_api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_stage" "cf_turnstile_default_stage" {
  api_id      = aws_apigatewayv2_api.cf_turnstile_api.id
  name        = "$default"
  auto_deploy = true
}

