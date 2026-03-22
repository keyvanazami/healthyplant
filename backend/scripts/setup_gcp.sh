#!/bin/bash
set -euo pipefail

# -------------------------------------------------------
# setup_gcp.sh — One-time GCP project setup for Healthy Plant
# -------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

APP_NAME="healthyplant"
REGION="${GCP_REGION:-us-central1}"
STATE_BUCKET="${APP_NAME}-terraform-state"
SA_NAME="${APP_NAME}-deployer"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
info()  { printf "\033[1;34m[INFO]\033[0m  %s\n" "$*"; }
ok()    { printf "\033[1;32m[OK]\033[0m    %s\n" "$*"; }
err()   { printf "\033[1;31m[ERR]\033[0m   %s\n" "$*" >&2; }

# -------------------------------------------------------
# Pre-flight: check for gcloud CLI
# -------------------------------------------------------
if ! command -v gcloud &>/dev/null; then
  err "gcloud CLI is not installed. Install it from https://cloud.google.com/sdk/docs/install"
  exit 1
fi
ok "gcloud CLI found: $(gcloud --version 2>/dev/null | head -1)"

# -------------------------------------------------------
# Project selection
# -------------------------------------------------------
if [[ -n "${GCP_PROJECT_ID:-}" ]]; then
  PROJECT_ID="$GCP_PROJECT_ID"
  info "Using project from GCP_PROJECT_ID env var: $PROJECT_ID"
else
  read -rp "Enter your GCP project ID (or leave blank to create one): " PROJECT_ID
fi

if [[ -z "$PROJECT_ID" ]]; then
  PROJECT_ID="${APP_NAME}-$(date +%s | tail -c 7)"
  info "Creating new project: $PROJECT_ID"
  gcloud projects create "$PROJECT_ID" --name="Healthy Plant"
fi

gcloud config set project "$PROJECT_ID"
ok "Active project: $PROJECT_ID"

# -------------------------------------------------------
# Enable billing check
# -------------------------------------------------------
BILLING=$(gcloud billing projects describe "$PROJECT_ID" --format="value(billingAccountName)" 2>/dev/null || true)
if [[ -z "$BILLING" ]]; then
  err "No billing account linked to project $PROJECT_ID."
  err "Link one at https://console.cloud.google.com/billing/linkedaccount?project=$PROJECT_ID"
  exit 1
fi
ok "Billing enabled"

# -------------------------------------------------------
# Enable required APIs
# -------------------------------------------------------
APIS=(
  run.googleapis.com
  firestore.googleapis.com
  cloudfunctions.googleapis.com
  storage.googleapis.com
  cloudscheduler.googleapis.com
  firebase.googleapis.com
  cloudbuild.googleapis.com
  artifactregistry.googleapis.com
  iam.googleapis.com
)

info "Enabling ${#APIS[@]} APIs (this may take a minute)..."
for api in "${APIS[@]}"; do
  gcloud services enable "$api" --quiet
done
ok "All APIs enabled"

# -------------------------------------------------------
# Create deployer service account
# -------------------------------------------------------
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

if gcloud iam service-accounts describe "$SA_EMAIL" &>/dev/null; then
  info "Service account $SA_EMAIL already exists"
else
  info "Creating service account: $SA_NAME"
  gcloud iam service-accounts create "$SA_NAME" \
    --display-name="Healthy Plant Deployer"
fi

ROLES=(
  roles/run.admin
  roles/cloudfunctions.admin
  roles/storage.admin
  roles/datastore.owner
  roles/cloudscheduler.admin
  roles/iam.serviceAccountUser
  roles/cloudbuild.builds.editor
)

for role in "${ROLES[@]}"; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SA_EMAIL" \
    --role="$role" \
    --quiet >/dev/null
done
ok "Service account roles configured"

# -------------------------------------------------------
# Set up Firestore in Native mode
# -------------------------------------------------------
info "Creating Firestore database in Native mode..."
if gcloud firestore databases describe --project="$PROJECT_ID" &>/dev/null; then
  info "Firestore database already exists"
else
  gcloud firestore databases create \
    --project="$PROJECT_ID" \
    --location="$REGION" \
    --type=firestore-native \
    --quiet
fi
ok "Firestore ready"

# -------------------------------------------------------
# Initialize Terraform backend (GCS bucket for state)
# -------------------------------------------------------
info "Creating Terraform state bucket: gs://$STATE_BUCKET"
if gsutil ls -b "gs://$STATE_BUCKET" &>/dev/null; then
  info "State bucket already exists"
else
  gsutil mb -p "$PROJECT_ID" -l "$REGION" "gs://$STATE_BUCKET"
  gsutil versioning set on "gs://$STATE_BUCKET"
fi
ok "Terraform state bucket ready"

# -------------------------------------------------------
# Summary & next steps
# -------------------------------------------------------
echo ""
echo "==========================================="
echo "  GCP Setup Complete"
echo "==========================================="
echo ""
echo "  Project ID:      $PROJECT_ID"
echo "  Region:          $REGION"
echo "  Service Account: $SA_EMAIL"
echo "  State Bucket:    gs://$STATE_BUCKET"
echo ""
echo "Next steps:"
echo "  1. Copy terraform.tfvars.example to terraform.tfvars and fill in values:"
echo "       cp backend/terraform/terraform.tfvars.example backend/terraform/terraform.tfvars"
echo "  2. Initialize Terraform:"
echo "       cd backend/terraform && terraform init"
echo "  3. Plan and apply:"
echo "       terraform plan"
echo "       terraform apply"
echo "  4. Deploy the API:"
echo "       bash backend/scripts/deploy_api.sh"
echo "  5. Deploy Cloud Functions:"
echo "       bash backend/scripts/deploy_functions.sh"
echo ""
