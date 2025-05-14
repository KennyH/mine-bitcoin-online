variable "environment" {
  description = "The environment (e.g., dev, prod)"
  type        = string
}

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
}

variable "pi_thing_name" {
  description = "The base name for the IoT Thing"
  type        = string
  default     = "piBtcNode"
}

variable "pool_payout_address" {
  description = "The Bitcoin address for the mining pool payout (lambda will need this)."
  type        = string
  sensitive   = true
}

variable "template_bucket_name" {
  description = "The base name for the S3 bucket storing templates"
  type        = string
  default     = "bitcoin-miner-templates"
}

variable "work_queue_name" {
  description = "The base name for the SQS work queues"
  type        = string
  default     = "bitcoin-miner-work-queue"
}

variable "submission_queue_name" {
  description = "The base name for the SQS submission queues"
  type        = string
  default     = "bitcoin-miner-submission-queue"
}

variable "submission_status_table_name" {
  description = "The base name for the DynamoDB table storing submission statuses"
  type        = string
  default     = "bitcoin-miner-submission-status"
}

variable "networks" {
  description = "List of Bitcoin networks to configure resources for"
  type        = list(string)
  default     = ["mainnet", "testnet", "regtest"]
}
