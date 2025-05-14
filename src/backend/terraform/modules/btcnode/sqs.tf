resource "aws_sqs_queue" "submission_queue" {
  for_each = toset(var.networks)
  name     = "${var.environment}-${var.submission_queue_name}-${each.value}"
  delay_seconds = 0
  max_message_size = 262144 # Max SQS message size
  message_retention_seconds = 345600 # 4 days
  receive_wait_time_seconds = 10 # Enable long polling
  visibility_timeout_seconds = 300 # 5 minutes

  tags = {
    Environment = var.environment
    Network     = each.value
    Project     = "BitcoinBrowserMiner"
  }
}