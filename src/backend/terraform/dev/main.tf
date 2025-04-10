provider "aws" {
  region = var.aws_region
}

# Second provider for us-east-1 (used only for ACM)
provider "aws" {
  alias  = "useast1"
  region = "us-east-1"
}

module "btcminer_backend" {
  source             = "../modules/btcminer_backend"
  environment        = var.environment
  domain_name        = var.domain_name
  aws_region         = var.aws_region

  providers = {
    aws.acm = aws.useast1
  }
}