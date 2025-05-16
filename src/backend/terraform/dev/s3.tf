resource "aws_s3_bucket" "demo_website_bucket" {
  bucket = "vulnerability-mvp-demo-website-${lower(replace(uuid(), "-", ""))}"

  tags = {
    Environment = "Demo"
    Project     = "VulnerabilityMVP"
  }
}

resource "aws_s3_bucket_website_configuration" "demo_website_config" {
  bucket = aws_s3_bucket.demo_website_bucket.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.demo_website_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_object" "demo_html_object" {
  bucket = aws_s3_bucket.demo_website_bucket.id 
  key    = "index.html"                        
  source = "index.html"                        

  content_type = "text/html"

  etag = filemd5("index.html")
}
