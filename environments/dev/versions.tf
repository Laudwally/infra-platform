terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Configure via: terraform init -backend-config=backend.hcl
  # (kept out of version control since bucket/table names are account-specific)
  backend "s3" {}
}

provider "aws" {
  region = "us-east-1"
}
