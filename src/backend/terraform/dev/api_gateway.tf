# Using api gateway for this demo, as AppSync requires
# auth and I don't really have time to setup Cognito and 
# get auth working to use it. Just building a one-shot
# classification demo.


# Create the API Gateway REST API
resource "aws_api_gateway_rest_api" "vulnerability_api" {
  name        = "VulnerabilityMVPAPI"
  description = "API Gateway for the Vulnerability MVP"
}

# Create an API Gateway resource (e.g., "/demo")
resource "aws_api_gateway_resource" "demo_resource" {
  rest_api_id = aws_api_gateway_rest_api.vulnerability_api.id
  parent_id   = aws_api_gateway_rest_api.vulnerability_api.root_resource_id
  path_part   = "demo"
}

# Create a GET method for the resource
resource "aws_api_gateway_method" "demo_method" {
  rest_api_id   = aws_api_gateway_rest_api.vulnerability_api.id
  resource_id   = aws_api_gateway_resource.demo_resource.id
  http_method   = "GET"
  authorization = "NONE" # No auth
}

# Set up the integration between the GET method and the Lambda function
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.vulnerability_api.id
  resource_id             = aws_api_gateway_resource.demo_resource.id
  http_method             = aws_api_gateway_method.demo_method.http_method
  integration_http_method = "POST" # Lambda integrations use POST
  type                    = "AWS_PROXY" # Use the AWS_PROXY integration for simplicity
  uri                     = aws_lambda_function.vulnerability_lambda.invoke_arn
}

# Create a POST method for the resource
resource "aws_api_gateway_method" "demo_method_post" {
  rest_api_id   = aws_api_gateway_rest_api.vulnerability_api.id
  resource_id   = aws_api_gateway_resource.demo_resource.id
  http_method   = "POST" # Define the POST method
  authorization = "NONE"
}

# Set up the integration between the POST method and the Lambda function
resource "aws_api_gateway_integration" "lambda_integration_post" {
  rest_api_id             = aws_api_gateway_rest_api.vulnerability_api.id
  resource_id             = aws_api_gateway_resource.demo_resource.id
  http_method             = aws_api_gateway_method.demo_method_post.http_method
  integration_http_method = "POST" # Lambda integrations still use POST
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.vulnerability_lambda.invoke_arn
}

# Deploy the API Gateway
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.vulnerability_api.id
  # This is needed to redeploy the API when changes are made
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.demo_resource.id,
      aws_api_gateway_method.demo_method.id,
      aws_api_gateway_integration.lambda_integration.id,
      aws_api_gateway_method.demo_method_post.id,
      aws_api_gateway_integration.lambda_integration_post.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create a stage for the deployment
resource "aws_api_gateway_stage" "dev_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.vulnerability_api.id
  stage_name    = "dev"
}

# Permission for API Gateway to invoke the Lambda function
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.vulnerability_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.vulnerability_api.execution_arn}/*/*"
}

output "invoke_url" {
  description = "The invoke URL for the API Gateway stage"
  value       = "${aws_api_gateway_stage.dev_stage.invoke_url}/${aws_api_gateway_resource.demo_resource.path_part}"
}