terraform {
  backend "s3" {
    region         = "me-south-1"
    bucket         = "the-sun-must-die"
    key            = "moon/sun/terraform.tfstate"
    dynamodb_table = "the-moon-has-never-been-there"
    encrypt        = true
 }
}
