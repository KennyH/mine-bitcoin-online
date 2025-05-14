resource "aws_dynamodb_table" "submission_status" {
  name             = "${var.environment}-${var.submission_status_table_name}"
  billing_mode     = "PAY_PER_REQUEST" # Or PROVISIONED
  hash_key         = "SubmissionID"

  attribute {
    name = "SubmissionID"
    type = "S"
  }

  tags = {
    Environment = var.environment
    Project     = "BitcoinBrowserMiner"
  }
}