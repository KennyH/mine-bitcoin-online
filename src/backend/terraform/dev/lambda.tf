resource "aws_iam_role" "lambda_role" {
  name = "vulnerability_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "lambda_logging_policy" {
  name = "vulnerability_lambda_logging_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/${aws_lambda_function.vulnerability_lambda.function_name}:*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logging_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}

# Zip up the Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "../lambda"
  #  source_dir  = "./terraform/lambda"
  output_path = "vulnerability_lambda.zip"
}

# Create the Lambda function
resource "aws_lambda_function" "vulnerability_lambda" {
  function_name    = "vulnerability_mvp_lambda"
  runtime          = "python3.11"
  role             = aws_iam_role.lambda_role.arn
  handler          = "emotional_signal_processing.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  filename         = data.archive_file.lambda_zip.output_path

  timeout = 60

  environment {
    variables = {
      OPENAI_API_KEY = "YOUR_OPENAI_API_KEY" # Replace with your actual key or use a secure method
    }
  }

  # Use your arn from uploading (see comment below)
  layers = [
    "arn:aws:lambda:us-west-2:916175830325:layer:openai-python311:2" # Hardcoded Layer Version ARN
  ]
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.vulnerability_lambda.function_name}"
  retention_in_days = 3 # Set to 3 days
}

# # Run these commands to build and upload a recent OpenAI Lambda Layer:
# docker run --rm -it -v $PWD/layer:/var/task \
#   public.ecr.aws/sam/build-python3.11:latest \
#   /bin/bash -c "
#       pip install 'openai==1.*' -t /var/task/python/lib/python3.11/site-packages && \
#       # Set read permissions for owner, group, and others recursively
#       chmod -R 755 /var/task/python && \
#       cd /var/task && zip -r /var/task/openai-layer.zip python"
# # # publish it
# aws lambda publish-layer-version \
#   --layer-name openai-python311 \
#   --zip-file fileb://layer/openai-layer.zip \
#   --compatible-runtimes python3.11
#   --compatible-architectures x86_64
