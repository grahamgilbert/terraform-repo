provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket  = "grahamgilbert-terraform"
    region  = "us-east-1"
    encrypt = "true"
    key     = "ggdotcom/terraform_state"
  }
}

variable "www_domain_name" {
  default = "www.grahamgilbert.com"
}

variable "root_domain_name" {
  default = "grahamgilbert.com"
}

variable "bucket_name" {
  default = "grahamgilbertcom"
}

variable "301_name" {
  default = "grahamgilbert-301"
}
