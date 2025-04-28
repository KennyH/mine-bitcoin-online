resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "mine-bitcoin-online-frontend-${var.environment}"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

#new
resource "aws_s3_bucket_website_configuration" "frontend_bucket_website" {
  bucket = aws_s3_bucket.frontend_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404.html"
  }
}

resource "aws_s3_bucket_versioning" "frontend_bucket_versioning" {
  bucket = aws_s3_bucket.frontend_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

#new
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.frontend_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Principal: "*",
        Action: "s3:GetObject",
        Resource: "${aws_s3_bucket.frontend_bucket.arn}/*"
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

# resource "aws_s3_bucket_policy" "bucket_policy" {
#   bucket = aws_s3_bucket.frontend_bucket.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       # Principal = {
#       #   AWS = aws_cloudfront_origin_access_identity.origin_identity.iam_arn
#       # }
#       Principal = "*"
#       Action   = ["s3:GetObject"]
#       Resource = ["${aws_s3_bucket.frontend_bucket.arn}/*"]
#     }]
#   })
# }

resource "aws_s3_bucket_public_access_block" "public_block" {
  bucket                  = aws_s3_bucket.frontend_bucket.id
  block_public_acls       = true    # use bucket policy only
  block_public_policy     = false   # public read policy above
  ignore_public_acls      = true    # ignore object ACLs
  restrict_public_buckets = false   # public read policy above
}
