terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Primary region — Amplify app lives here
provider "aws" {
  region = "us-west-2"
}

# CloudFront WAF, ACM certs for CloudFront, and global WAFv2 must all be in us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
