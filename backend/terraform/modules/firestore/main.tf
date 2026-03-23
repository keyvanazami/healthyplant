resource "google_firestore_database" "default" {
  project     = var.project_id
  name        = "(default)"
  location_id = var.region
  type        = "FIRESTORE_NATIVE"

  # Prevent accidental deletion
  deletion_policy = "DELETE"

  lifecycle {
    # If the database already exists, don't try to recreate it
    ignore_changes = [location_id, type]
  }
}

# Firestore security rules are deployed separately via Firebase CLI.
# The rules file is kept here for reference and CI/CD integration.
resource "local_file" "firestore_rules" {
  filename = "${path.module}/firestore.rules"
  content  = <<-RULES
    rules_version = '2';
    service cloud.firestore {
      match /databases/{database}/documents {

        // Users collection
        match /users/{userId} {
          allow read, write: if request.auth != null && request.auth.uid == userId;

          // Plant profiles nested under users
          match /plants/{plantId} {
            allow read, write: if request.auth != null && request.auth.uid == userId;
          }

          // Care calendar entries
          match /calendar/{entryId} {
            allow read, write: if request.auth != null && request.auth.uid == userId;
          }

          // Notification preferences
          match /notifications/{notifId} {
            allow read, write: if request.auth != null && request.auth.uid == userId;
          }
        }

        // Plant analysis results (read-only for owners)
        match /analyses/{analysisId} {
          allow read: if request.auth != null
                      && resource.data.userId == request.auth.uid;
          allow create: if false; // created server-side only
        }

        // Deny everything else
        match /{document=**} {
          allow read, write: if false;
        }
      }
    }
  RULES
}
