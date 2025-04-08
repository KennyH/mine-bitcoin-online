terraform {
  backend "s3" {
    bucket         = "mine-bitcoin-online-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = "mine-bitcoin-online-terraform-state-lock"
    encrypt        = true
  }
}
