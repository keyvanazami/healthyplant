# -------------------------------------------------------
# Service account for Cloud Functions
# -------------------------------------------------------
resource "google_service_account" "functions_sa" {
  project      = var.project_id
  account_id   = "${var.app_name}-functions-sa"
  display_name = "Healthy Plant Cloud Functions"
}

resource "google_project_iam_member" "functions_firestore" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.functions_sa.email}"
}

resource "google_project_iam_member" "functions_storage" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.functions_sa.email}"
}

resource "google_project_iam_member" "functions_pubsub" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.functions_sa.email}"
}

resource "google_project_iam_member" "functions_eventarc" {
  project = var.project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.functions_sa.email}"
}

# -------------------------------------------------------
# Source bucket for function code
# -------------------------------------------------------
resource "google_storage_bucket" "functions_source" {
  name     = "${var.project_id}-${var.app_name}-functions-src"
  location = var.region
  project  = var.project_id

  uniform_bucket_level_access = true

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30
    }
  }
}

# -------------------------------------------------------
# 1. on_profile_create — triggered by Firestore document creation
# -------------------------------------------------------
resource "google_cloudfunctions2_function" "on_profile_create" {
  name     = "${var.app_name}-on-profile-create-${var.environment}"
  location = var.region
  project  = var.project_id

  build_config {
    runtime     = "python312"
    entry_point = "on_profile_create"

    source {
      storage_source {
        bucket = google_storage_bucket.functions_source.name
        object = "on_profile_create.zip"
      }
    }
  }

  service_config {
    max_instance_count    = 10
    min_instance_count    = 0
    available_memory      = "256M"
    timeout_seconds       = 60
    service_account_email = google_service_account.functions_sa.email

    environment_variables = {
      GCS_BUCKET        = var.gcs_bucket
      FIRESTORE_PROJECT = var.project_id
      ENVIRONMENT       = var.environment
    }
  }

  event_trigger {
    trigger_region = var.firestore_region
    event_type     = "google.cloud.firestore.document.v1.created"
    event_filters {
      attribute = "database"
      value     = "(default)"
    }
    event_filters {
      attribute = "document"
      value     = "users/{userId}/plants/{plantId}"
      operator  = "match-path-pattern"
    }
  }
}

# -------------------------------------------------------
# 2. daily_calendar_sync — scheduled daily
# -------------------------------------------------------
resource "google_cloudfunctions2_function" "daily_calendar_sync" {
  name     = "${var.app_name}-daily-calendar-sync-${var.environment}"
  location = var.region
  project  = var.project_id

  build_config {
    runtime     = "python312"
    entry_point = "daily_calendar_sync"

    source {
      storage_source {
        bucket = google_storage_bucket.functions_source.name
        object = "daily_calendar_sync.zip"
      }
    }
  }

  service_config {
    max_instance_count    = 3
    min_instance_count    = 0
    available_memory      = "256M"
    timeout_seconds       = 300
    service_account_email = google_service_account.functions_sa.email

    environment_variables = {
      GCS_BUCKET        = var.gcs_bucket
      FIRESTORE_PROJECT = var.project_id
      ENVIRONMENT       = var.environment
    }
  }
}

resource "google_cloud_scheduler_job" "daily_calendar_sync" {
  name     = "${var.app_name}-daily-calendar-sync-${var.environment}"
  project  = var.project_id
  region   = var.region
  schedule = "0 6 * * *" # 6:00 AM daily

  http_target {
    uri         = google_cloudfunctions2_function.daily_calendar_sync.url
    http_method = "POST"

    oidc_token {
      service_account_email = google_service_account.functions_sa.email
    }
  }
}

# -------------------------------------------------------
# 3. send_notifications — scheduled every 30 minutes
# -------------------------------------------------------
resource "google_cloudfunctions2_function" "send_notifications" {
  name     = "${var.app_name}-send-notifications-${var.environment}"
  location = var.region
  project  = var.project_id

  build_config {
    runtime     = "python312"
    entry_point = "send_notifications"

    source {
      storage_source {
        bucket = google_storage_bucket.functions_source.name
        object = "send_notifications.zip"
      }
    }
  }

  service_config {
    max_instance_count    = 5
    min_instance_count    = 0
    available_memory      = "256M"
    timeout_seconds       = 120
    service_account_email = google_service_account.functions_sa.email

    environment_variables = {
      GCS_BUCKET        = var.gcs_bucket
      FIRESTORE_PROJECT = var.project_id
      ENVIRONMENT       = var.environment
    }
  }
}

resource "google_cloud_scheduler_job" "send_notifications" {
  name     = "${var.app_name}-send-notifications-${var.environment}"
  project  = var.project_id
  region   = var.region
  schedule = "*/30 * * * *" # every 30 minutes

  http_target {
    uri         = google_cloudfunctions2_function.send_notifications.url
    http_method = "POST"

    oidc_token {
      service_account_email = google_service_account.functions_sa.email
    }
  }
}

# -------------------------------------------------------
# Outputs
# -------------------------------------------------------
output "function_urls" {
  value = {
    on_profile_create  = google_cloudfunctions2_function.on_profile_create.url
    daily_calendar_sync = google_cloudfunctions2_function.daily_calendar_sync.url
    send_notifications  = google_cloudfunctions2_function.send_notifications.url
  }
}
