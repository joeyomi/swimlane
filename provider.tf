# INSTALL REQUIRED PROVIDERS.
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.0"
    }
  }
  required_version = ">= 0.13"
  backend "gcs" {
    bucket = "brave-data-sandbox-cicd-terraform-state"
    prefix = "swimlane"
  }
}
