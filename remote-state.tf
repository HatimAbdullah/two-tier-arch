terraform {
  backend "s3" {
    region         = "me-south-1"
    bucket         = "the-sun-must-die"
    key            = "moon/sun/terraform.tfstate"
    dynamodb_table = "the-moon-has-never-been-there"
    encrypt        = true
    access_key     = $aws_access_key_id
    secret_key     = $aws_secret_access_key_id
 }
}
