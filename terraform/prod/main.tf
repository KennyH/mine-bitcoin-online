provider "aws" {
  region = "us-west-2"
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

  providers = {
    aws.acm = aws.useast1
  }
}