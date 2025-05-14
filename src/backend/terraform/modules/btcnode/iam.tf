locals {
  iot_publish_resources = [
    for network in var.networks : "arn:aws:iot:${var.aws_region}:*:topic/pi-miner/${var.environment}/${network}/new-block"
  ]

  sqs_submission_resources = [
    for network in var.networks : aws_sqs_queue.submission_queue[network].arn
  ]

  dynamodb_submission_resource = [
    aws_dynamodb_table.submission_status.arn
  ]

  s3_template_bucket_resources = [
    aws_s3_bucket.template_bucket.arn
  ]

  assumed_role_resources = concat(
    local.iot_publish_resources,
    local.sqs_submission_resources,
    local.dynamodb_submission_resource,
    local.s3_template_bucket_resources
  )
}

resource "aws_iam_role" "pi_node_assumed_role" {
  name               = "${var.pi_thing_name}-${var.environment}-assumed-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "credentials.iot.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "iot:CertificateArn" = aws_iot_certificate.pi_node_cert.arn
          }
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = "BitcoinBrowserMiner"
  }
}

resource "aws_iam_policy" "pi_node_assumed_policy" {
  name        = "${var.pi_thing_name}-${var.environment}-assumed-policy"
  description = "Policy for the Pi node assumed role in ${var.environment}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iot:Publish",
          "s3:PutObject",
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:ChangeMessageVisibility",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:GetItem",
        ]
        Resource = local.assumed_role_resources
      },
      {
         Effect = "Allow"
         Action = ["sqs:ListQueues"]
         Resource = "*"
      },
      {
         Effect = "Allow"
         Action = ["dynamodb:ListTables"]
         Resource = "*"
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = "BitcoinBrowserMiner"
  }
}

resource "aws_iam_role_policy_attachment" "pi_node_policy_attach" {
  role       = aws_iam_role.pi_node_assumed_role.name
  policy_arn = aws_iam_policy.pi_node_assumed_policy.arn
}
