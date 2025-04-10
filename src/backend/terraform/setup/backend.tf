terraform {
  backend "s3" {
    bucket         = "mine-bitcoin-online-terraform-state"
    key            = "setup/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "mine-bitcoin-online-terraform-state-lock"
    encrypt        = true
  }
}
