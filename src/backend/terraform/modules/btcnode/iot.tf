resource "aws_iot_certificate" "pi_node_cert" {
  active = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iot_thing" "pi_node" {
  name = "${var.pi_thing_name}-${var.environment}"

  attributes = {
    environment = var.environment
    device_type = "Raspberry-Pi-5-8GB-2TBnvme"
  }
}

resource "aws_iot_thing_principal_attachment" "pi_node_cert_attach" {
  principal = aws_iot_certificate.pi_node_cert.arn
  thing     = aws_iot_thing.pi_node.name
}

resource "aws_iot_policy" "pi_node_policy" {
  name = "${var.pi_thing_name}-${var.environment}-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "iot:Connect",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:iot:${var.aws_region}:*:client/${aws_iot_thing.pi_node.name}"
        ]
      },
      {
        Action = [
          "iot:Publish",
        ]
        Effect = "Allow"
        # Allow publishing to network-specific new-block topics
        Resource = [for network in var.networks : "arn:aws:iot:${var.aws_region}:*:topic/pi-miner/${var.environment}/${network}/new-block"]
      },
      {
        Action = [
          "iot:AssumeRoleWithCertificate",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:iot:${var.aws_region}:*:rolealias/${var.pi_thing_name}-${var.environment}-role-alias"
        ]
      },
    ]
  })

  tags = {
    Environment = var.environment
    Project     = "BitcoinBrowserMiner"
  }
}

resource "aws_iot_policy_attachment" "pi_node_policy_attach" {
  policy = aws_iot_policy.pi_node_policy.name
  target = aws_iot_certificate.pi_node_cert.arn
}

resource "aws_iot_role_alias" "pi_node_role_alias" {
  alias = "${var.pi_thing_name}-${var.environment}-role-alias"
  role_arn = aws_iam_role.pi_node_assumed_role.arn

  tags = {
    Environment = var.environment
    Project     = "BitcoinBrowserMiner"
  }
}
