provider "aws" {
  region = var.aws_region
}

# Second provider for us-east-1 (used only for ACM)
provider "aws" {
  alias  = "useast1"
  region = "us-east-1"
}

module "website" {
  source               = "../modules/website"
  environment          = var.environment
  domain_name          = var.domain_name
  aws_region           = var.aws_region
  turnstile_secret_key = var.turnstile_secret_key

  providers = {
    aws.acm = aws.useast1
  }
}

module "btcnode" {
  source        = "../modules/btcnode"
  environment   = var.environment
  aws_region    = var.aws_region
  pi_thing_name = "piBtcNode" 
  pool_payout_address = var.pool_payout_address # Pass this from the root variables
}
