terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.42.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
  shared_config_files      = ["/home/ubuntu/.aws/config"]
  shared_credentials_files = ["/home/ubuntu/.aws/credentials"]
  profile = "yash"
}