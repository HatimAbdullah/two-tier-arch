terraform {
  backend "s3" {
    region         = "me-south-1"
    bucket         = "the-sun-must-die"
    key            = "moon/sun/terraform.tfstate"
    dynamodb_table = "the-moon-has-never-been-there"
    encrypt        = true
    access_key     = "AKIA3H33RTPCPJODKMHV"
    secret_key     = "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"
  }
}
