resource "google_storage_bucket" "plant_photos" {
  name     = "${var.project_id}-${var.app_name}-photos-${var.environment}"
  location = var.region
  project  = var.project_id

  uniform_bucket_level_access = true
  force_destroy               = false

  # CORS configuration for direct uploads from mobile/web clients
  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "PUT", "POST", "OPTIONS"]
    response_header = ["Content-Type", "Content-Length", "Content-MD5"]
    max_age_seconds = 3600
  }

  # Lifecycle rules
  lifecycle_rule {
    action {
      type = "SetStorageClass"
      storage_class = "NEARLINE"
    }
    condition {
      age = 90 # Move to Nearline after 90 days
    }
  }

  lifecycle_rule {
    action {
      type = "SetStorageClass"
      storage_class = "COLDLINE"
    }
    condition {
      age = 365 # Move to Coldline after 1 year
    }
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 730 # Delete after 2 years
    }
  }

  versioning {
    enabled = false
  }
}

output "bucket_name" {
  value = google_storage_bucket.plant_photos.name
}
