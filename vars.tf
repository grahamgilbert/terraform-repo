provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "grahamgilbert"

    workspaces {
      name = "terraform-repo"
    }
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

variable "three_oh_one_name" {
  default = "grahamgilbert-301"
}

variable "gcp_project" {
  default = "terraform-repo"
}

variable "gcp_region" {
  default = "us-central1"
}
