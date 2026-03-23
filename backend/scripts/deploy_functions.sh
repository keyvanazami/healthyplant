#!/bin/bash
set -euo pipefail

# -------------------------------------------------------
# deploy_functions.sh — Deploy Cloud Functions & Scheduler jobs
# -------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FUNCTIONS_DIR="${BACKEND_DIR}/functions"

APP_NAME="${APP_NAME:-healthyplant}"
ENVIRONMENT="${ENVIRONMENT:-prod}"
REGION="${GCP_REGION:-us-central1}"
PROJECT_ID="${GCP_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"
SA_EMAIL="${APP_NAME}-functions-sa@${PROJECT_ID}.iam.gserviceaccount.com"

# -------------------------------------------------------
# Helpers
# -------------------------------------------------------
info()  { printf "\033[1;34m[INFO]\033[0m  %s\n" "$*"; }
ok()    { printf "\033[1;32m[OK]\033[0m    %s\n" "$*"; }
err()   { printf "\033[1;31m[ERR]\033[0m   %s\n" "$*" >&2; }

# -------------------------------------------------------
# Pre-flight checks
# -------------------------------------------------------
if [[ -z "$PROJECT_ID" ]]; then
  err "No GCP project set. Run: gcloud config set project YOUR_PROJECT_ID"
  exit 1
fi

if [[ ! -d "$FUNCTIONS_DIR" ]]; then
  err "Functions directory not found: $FUNCTIONS_DIR"
  err "Create your function source code there before deploying."
  exit 1
fi

info "Project:          $PROJECT_ID"
info "Region:           $REGION"
info "Service Account:  $SA_EMAIL"
info "Functions Dir:    $FUNCTIONS_DIR"
echo ""

# -------------------------------------------------------
# 1. Deploy on_profile_create (Firestore trigger)
# -------------------------------------------------------
info "Deploying on_profile_create..."
FIRESTORE_REGION="${FIRESTORE_REGION:-us-central1}"
gcloud functions deploy "${APP_NAME}-on-profile-create-${ENVIRONMENT}" \
  --gen2 \
  --region="$REGION" \
  --runtime=python312 \
  --entry-point=on_profile_create \
  --source="${FUNCTIONS_DIR}/on_profile_create" \
  --trigger-event-filters="type=google.cloud.firestore.document.v1.created" \
  --trigger-event-filters="database=(default)" \
  --trigger-event-filters-path-pattern="document=users/{userId}/plants/{plantId}" \
  --trigger-location="$FIRESTORE_REGION" \
  --service-account="$SA_EMAIL" \
  --memory=256Mi \
  --timeout=60s \
  --quiet
ok "on_profile_create deployed"

# -------------------------------------------------------
# 2. Deploy daily_calendar_sync (HTTP, called by Scheduler)
# -------------------------------------------------------
info "Deploying daily_calendar_sync..."
gcloud functions deploy "${APP_NAME}-daily-calendar-sync-${ENVIRONMENT}" \
  --gen2 \
  --region="$REGION" \
  --runtime=python312 \
  --entry-point=daily_calendar_sync \
  --source="${FUNCTIONS_DIR}/daily_calendar_sync" \
  --trigger-http \
  --no-allow-unauthenticated \
  --service-account="$SA_EMAIL" \
  --memory=256Mi \
  --timeout=300s \
  --quiet
ok "daily_calendar_sync deployed"

SYNC_URL=$(gcloud functions describe "${APP_NAME}-daily-calendar-sync-${ENVIRONMENT}" \
  --region="$REGION" --gen2 --format="value(serviceConfig.uri)")

# -------------------------------------------------------
# 3. Deploy send_notifications (HTTP, called by Scheduler)
# -------------------------------------------------------
info "Deploying send_notifications..."
gcloud functions deploy "${APP_NAME}-send-notifications-${ENVIRONMENT}" \
  --gen2 \
  --region="$REGION" \
  --runtime=python312 \
  --entry-point=send_notifications \
  --source="${FUNCTIONS_DIR}/send_notifications" \
  --trigger-http \
  --no-allow-unauthenticated \
  --service-account="$SA_EMAIL" \
  --memory=256Mi \
  --timeout=120s \
  --quiet
ok "send_notifications deployed"

NOTIF_URL=$(gcloud functions describe "${APP_NAME}-send-notifications-${ENVIRONMENT}" \
  --region="$REGION" --gen2 --format="value(serviceConfig.uri)")

# -------------------------------------------------------
# 4. Set up Cloud Scheduler jobs
# -------------------------------------------------------
info "Configuring Cloud Scheduler jobs..."

# Daily calendar sync — 6:00 AM every day
if gcloud scheduler jobs describe "${APP_NAME}-daily-calendar-sync-${ENVIRONMENT}" \
    --location="$REGION" &>/dev/null; then
  gcloud scheduler jobs update http "${APP_NAME}-daily-calendar-sync-${ENVIRONMENT}" \
    --location="$REGION" \
    --schedule="0 6 * * *" \
    --uri="$SYNC_URL" \
    --http-method=POST \
    --oidc-service-account-email="$SA_EMAIL" \
    --quiet
else
  gcloud scheduler jobs create http "${APP_NAME}-daily-calendar-sync-${ENVIRONMENT}" \
    --location="$REGION" \
    --schedule="0 6 * * *" \
    --uri="$SYNC_URL" \
    --http-method=POST \
    --oidc-service-account-email="$SA_EMAIL" \
    --quiet
fi
ok "Scheduler: daily_calendar_sync (0 6 * * *)"

# Send notifications — every 30 minutes
if gcloud scheduler jobs describe "${APP_NAME}-send-notifications-${ENVIRONMENT}" \
    --location="$REGION" &>/dev/null; then
  gcloud scheduler jobs update http "${APP_NAME}-send-notifications-${ENVIRONMENT}" \
    --location="$REGION" \
    --schedule="*/30 * * * *" \
    --uri="$NOTIF_URL" \
    --http-method=POST \
    --oidc-service-account-email="$SA_EMAIL" \
    --quiet
else
  gcloud scheduler jobs create http "${APP_NAME}-send-notifications-${ENVIRONMENT}" \
    --location="$REGION" \
    --schedule="*/30 * * * *" \
    --uri="$NOTIF_URL" \
    --http-method=POST \
    --oidc-service-account-email="$SA_EMAIL" \
    --quiet
fi
ok "Scheduler: send_notifications (*/30 * * * *)"

# -------------------------------------------------------
# 5. Verify deployments
# -------------------------------------------------------
echo ""
info "Verifying deployed functions..."
echo ""

for fn in \
  "${APP_NAME}-on-profile-create-${ENVIRONMENT}" \
  "${APP_NAME}-daily-calendar-sync-${ENVIRONMENT}" \
  "${APP_NAME}-send-notifications-${ENVIRONMENT}"; do

  STATUS=$(gcloud functions describe "$fn" \
    --region="$REGION" --gen2 \
    --format="value(state)" 2>/dev/null || echo "NOT_FOUND")
  if [[ "$STATUS" == "ACTIVE" ]]; then
    ok "$fn — ACTIVE"
  else
    err "$fn — $STATUS"
  fi
done

echo ""
echo "==========================================="
echo "  Cloud Functions Deployment Complete"
echo "==========================================="
echo ""
echo "  Scheduler jobs:"
echo "    - daily_calendar_sync : 0 6 * * *     -> $SYNC_URL"
echo "    - send_notifications  : */30 * * * *   -> $NOTIF_URL"
echo ""
