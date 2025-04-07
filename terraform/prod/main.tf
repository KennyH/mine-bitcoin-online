provider "aws" {
  region = "us-west-2"
}

module "siteup_backend" {
  source             = "../modules/btcminer_backend"
  environment        = var.environment
}