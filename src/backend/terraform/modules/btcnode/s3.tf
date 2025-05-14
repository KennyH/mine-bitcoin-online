# S3 bucket for storing block templates
resource "aws_s3_bucket" "template_bucket" {
  # Generate a unique bucket name using environment, base name, and a hash of the account ID
  bucket = "${var.environment}-${var.template_bucket_name}-${substr(sha1(data.aws_caller_identity.current.account_id), 0, 8)}" # Using first 8 chars of SHA1

  tags = {
    Environment = var.environment
    Project     = "BitcoinBrowserMiner"
  }
}

resource "aws_s3_bucket_ownership_controls" "template_bucket_ownership_controls" {
  bucket = aws_s3_bucket.template_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }

  depends_on = [aws_s3_bucket.template_bucket]
}

resource "aws_s3_bucket_public_access_block" "template_bucket_public_access_block" {
  bucket = aws_s3_bucket.template_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_policy" "template_bucket_policy" {
  bucket = aws_s3_bucket.template_bucket.id
  policy = data.aws_iam_policy_document.cloudfront_s3_access.json

  depends_on = [
    aws_s3_bucket.template_bucket,
    aws_s3_bucket_ownership_controls.template_bucket_ownership_controls,
    aws_s3_bucket_public_access_block.template_bucket_public_access_block,
  ]
}

data "aws_iam_policy_document" "cloudfront_s3_access" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]

    resources = [
      "${aws_s3_bucket.template_bucket.arn}/*"
    ]

    condition {
       test     = "StringEquals"
       variable = "AWS:SourceArn"
       values   = [aws_cloudfront_origin_access_control.template_bucket_oac.arn]
    }
  }
}
