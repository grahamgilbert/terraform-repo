provider "aws" {
  region = "us-east-1"
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

# GCP beta provider
provider "google-beta" {
  project = var.gcp_project
  region  = var.gcp_region
}
