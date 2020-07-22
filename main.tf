provider "aws" {
  profile = "fish"
  region  = "me-south-1"
}

module "wild-west" {
  name            = var.name
  source          = "./infra"
  key_name        = var.key_name
  public_key_path = var.public_key_path
}
