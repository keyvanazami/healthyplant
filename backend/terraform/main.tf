terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "healthyplant-terraform-state"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# -------------------------------------------------------
# Enable required APIs
# -------------------------------------------------------
locals {
  required_apis = [
    "run.googleapis.com",
    "firestore.googleapis.com",
    "cloudfunctions.googleapis.com",
    "storage.googleapis.com",
    "cloudscheduler.googleapis.com",
    "firebase.googleapis.com",
    "cloudbuild.googleapis.com",
    "eventarc.googleapis.com",
  ]
}

resource "google_project_service" "apis" {
  for_each = toset(local.required_apis)

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# -------------------------------------------------------
# Modules
# -------------------------------------------------------
module "cloud_storage" {
  source = "./modules/cloud_storage"

  project_id  = var.project_id
  region      = var.region
  app_name    = var.app_name
  environment = var.environment

  depends_on = [google_project_service.apis]
}

module "firestore" {
  source = "./modules/firestore"

  project_id  = var.project_id
  region      = var.region
  app_name    = var.app_name
  environment = var.environment

  depends_on = [google_project_service.apis]
}

module "cloud_run" {
  source = "./modules/cloud_run"

  project_id        = var.project_id
  region            = var.region
  app_name          = var.app_name
  environment       = var.environment
  anthropic_api_key = var.anthropic_api_key
  gcs_bucket        = module.cloud_storage.bucket_name

  depends_on = [google_project_service.apis]
}

module "cloud_functions" {
  source = "./modules/cloud_functions"

  project_id       = var.project_id
  region           = var.region
  app_name         = var.app_name
  environment      = var.environment
  gcs_bucket       = module.cloud_storage.bucket_name
  firestore_region = "us-central1"

  depends_on = [google_project_service.apis]
}
