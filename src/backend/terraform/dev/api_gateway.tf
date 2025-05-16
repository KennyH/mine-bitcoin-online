# Using api gateway for this demo, as AppSync requires
# auth and I don't really have time to setup Cognito and
# get auth working to use it. Just building a one-shot
# classification demo.

resource "aws_api_gateway_rest_api" "vulnerability_api" {
  name        = "VulnerabilityMVPAPI"
  description = "API Gateway for the Vulnerability MVP"
}

resource "aws_api_gateway_resource" "demo_resource" {
  rest_api_id = aws_api_gateway_rest_api.vulnerability_api.id
  parent_id   = aws_api_gateway_rest_api.vulnerability_api.root_resource_id
  path_part   = "demo"
}

resource "aws_api_gateway_method" "demo_method_get" {
  rest_api_id   = aws_api_gateway_rest_api.vulnerability_api.id
  resource_id   = aws_api_gateway_resource.demo_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "demo_method_get_200" {
  rest_api_id = aws_api_gateway_rest_api.vulnerability_api.id
  resource_id = aws_api_gateway_resource.demo_resource.id
  http_method = aws_api_gateway_method.demo_method_get.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Credentials" = true
  }
}


resource "aws_api_gateway_integration" "lambda_integration_get" {
  rest_api_id             = aws_api_gateway_rest_api.vulnerability_api.id
  resource_id             = aws_api_gateway_resource.demo_resource.id
  http_method             = aws_api_gateway_method.demo_method_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.vulnerability_lambda.invoke_arn
}

resource "aws_api_gateway_integration_response" "lambda_integration_get_200" {
  rest_api_id = aws_api_gateway_rest_api.vulnerability_api.id
  resource_id = aws_api_gateway_resource.demo_resource.id
  http_method = aws_api_gateway_method.demo_method_get.http_method
  status_code = aws_api_gateway_method_response.demo_method_get_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,GET'"
    "method.response.header.Access-Control-Allow-Credentials" = "'true'"
  }
}

resource "aws_api_gateway_method" "demo_method_post" {
  rest_api_id   = aws_api_gateway_rest_api.vulnerability_api.id
  resource_id   = aws_api_gateway_resource.demo_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "demo_method_post_200" {
  rest_api_id = aws_api_gateway_rest_api.vulnerability_api.id
  resource_id = aws_api_gateway_resource.demo_resource.id
  http_method = aws_api_gateway_method.demo_method_post.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Credentials" = true
  }
}

# Existing POST integration
resource "aws_api_gateway_integration" "lambda_integration_post" {
  rest_api_id             = aws_api_gateway_rest_api.vulnerability_api.id
  resource_id             = aws_api_gateway_resource.demo_resource.id
  http_method             = aws_api_gateway_method.demo_method_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.vulnerability_lambda.invoke_arn
}

resource "aws_api_gateway_integration_response" "lambda_integration_post_200" {
  rest_api_id = aws_api_gateway_rest_api.vulnerability_api.id
  resource_id = aws_api_gateway_resource.demo_resource.id
  http_method = aws_api_gateway_method.demo_method_post.http_method
  status_code = aws_api_gateway_method_response.demo_method_post_200.status_code # Link to the method response

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'" # Allow from any origin for the demo
    # For production, replace '*' with your CloudFront domain:
    # "method.response.header.Access-Control-Allow-Origin" = aws_cloudfront_distribution.s3_distribution.domain_name
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Credentials" = "'true'"
  }
}

resource "aws_api_gateway_method" "demo_method_options" {
  rest_api_id   = aws_api_gateway_rest_api.vulnerability_api.id
  resource_id   = aws_api_gateway_resource.demo_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "demo_method_options_200" {
  rest_api_id = aws_api_gateway_rest_api.vulnerability_api.id
  resource_id = aws_api_gateway_resource.demo_resource.id
  http_method = aws_api_gateway_method.demo_method_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Credentials" = true
  }
}

resource "aws_api_gateway_integration" "cors_options_integration" {
  rest_api_id             = aws_api_gateway_rest_api.vulnerability_api.id
  resource_id             = aws_api_gateway_resource.demo_resource.id
  http_method             = aws_api_gateway_method.demo_method_options.http_method
  type                    = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_integration_response" "options_integration_200" {
  rest_api_id = aws_api_gateway_rest_api.vulnerability_api.id
  resource_id = aws_api_gateway_resource.demo_resource.id
  http_method = aws_api_gateway_method.demo_method_options.http_method
  status_code = aws_api_gateway_method_response.demo_method_options_200.status_code # Link to the method response

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'" # Allow from any origin for the demo
    # For production, replace '*' with your CloudFront domain:
    # "method.response.header.Access-Control-Allow-Origin" = aws_cloudfront_distribution.s3_distribution.domain_name
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Credentials" = "'true'"
  }

  # Ensure this response maps to the 200 status code method response
  selection_pattern = ""
}


resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.vulnerability_api.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.demo_resource.id,
      aws_api_gateway_method.demo_method_get.id,
      aws_api_gateway_method_response.demo_method_get_200.id, 
      aws_api_gateway_integration.lambda_integration_get.id, 
      aws_api_gateway_integration_response.lambda_integration_get_200.id, 
      aws_api_gateway_method.demo_method_post.id,
      aws_api_gateway_method_response.demo_method_post_200.id,
      aws_api_gateway_integration.lambda_integration_post.id,
      aws_api_gateway_integration_response.lambda_integration_post_200.id, 
      aws_api_gateway_method.demo_method_options.id, 
      aws_api_gateway_method_response.demo_method_options_200.id, 
      aws_api_gateway_integration.cors_options_integration.id,
      aws_api_gateway_integration_response.options_integration_200.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "dev_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.vulnerability_api.id
  stage_name    = "dev"
}

output "invoke_url" {
  description = "The invoke URL for the API Gateway stage"
  value       = "${aws_api_gateway_stage.dev_stage.invoke_url}/${aws_api_gateway_resource.demo_resource.path_part}"
}
