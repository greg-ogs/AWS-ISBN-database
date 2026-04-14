terraform {
  backend "s3" {
    bucket         = "book-tf-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "book-tf-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}
