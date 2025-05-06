terraform {

  backend "s3" {
    bucket = "marten-tfstate"
    key = "tf/terraform.tfstate"
    region = "eu-north-1"
    profile = "sec"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  required_version = ">= 1.5.0"
}