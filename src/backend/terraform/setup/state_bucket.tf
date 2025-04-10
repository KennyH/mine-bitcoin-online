resource "aws_s3_bucket" "terraform_state" {
  bucket = "mine-bitcoin-online-terraform-state"
}

resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_kms_key" "terraform_state_key" {
  description = "KMS key for Terraform state bucket"
  enable_key_rotation  = true
}

resource "aws_kms_alias" "terraform_state_key_alias" {
  name          = "alias/mine-bitcoin-online-terraform-state-key"
  target_key_id = aws_kms_key.terraform_state_key.id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.terraform_state_key.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state_block" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name           = "mine-bitcoin-online-terraform-state-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.terraform_state_key.arn
  }

  point_in_time_recovery {
    enabled = true
  }
}
