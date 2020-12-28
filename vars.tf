provider "aws" {
  region = "us-east-1"
}

variable "terraform_token" {}

terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "grahamgilbert"

    workspaces {
      name = "terraform-repo"
    }

    credentials "app.terraform.io" {
      token = var.terraform_token
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

variable "billing_account_id" {}

variable "org_id" {
  default     = "742625797188"
  description = "The Google organization id in which to place the projects"
}

variable "root_id" {
  default = "organizations/742625797188"
}

variable "GOOGLE_CREDENTIALS" {}

variable "services" {
  type = list(string)
  default = [
    "logging.googleapis.com",
    "cloudbilling.googleapis.com",
  ]
}
