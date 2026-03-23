#!/bin/bash
set -euo pipefail

# -------------------------------------------------------
# deploy_api.sh — Build, push, and deploy the API to Cloud Run
# -------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

APP_NAME="${APP_NAME:-healthyplant}"
ENVIRONMENT="${ENVIRONMENT:-prod}"
REGION="${GCP_REGION:-us-central1}"
PROJECT_ID="${GCP_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}"

SERVICE_NAME="${APP_NAME}-api-${ENVIRONMENT}"
IMAGE="gcr.io/${PROJECT_ID}/${APP_NAME}-api"
TAG="${IMAGE}:$(git -C "$BACKEND_DIR" rev-parse --short HEAD 2>/dev/null || echo 'latest')"
TAG_LATEST="${IMAGE}:latest"

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

if ! command -v docker &>/dev/null; then
  err "Docker is not installed or not in PATH"
  exit 1
fi

info "Project:  $PROJECT_ID"
info "Service:  $SERVICE_NAME"
info "Region:   $REGION"
info "Image:    $TAG"

# -------------------------------------------------------
# Authenticate Docker with GCR
# -------------------------------------------------------
info "Configuring Docker for GCR..."
gcloud auth configure-docker --quiet

# -------------------------------------------------------
# Build the Docker image
# -------------------------------------------------------
info "Building Docker image..."
docker build --platform linux/amd64 -t "$TAG" -t "$TAG_LATEST" "$BACKEND_DIR/api"

# -------------------------------------------------------
# Push to Google Container Registry
# -------------------------------------------------------
info "Pushing image to GCR..."
docker push "$TAG"
docker push "$TAG_LATEST"
ok "Image pushed: $TAG"

# -------------------------------------------------------
# Deploy to Cloud Run
# -------------------------------------------------------
info "Deploying to Cloud Run..."
gcloud run deploy "$SERVICE_NAME" \
  --image="$TAG_LATEST" \
  --region="$REGION" \
  --platform=managed \
  --allow-unauthenticated \
  --port=8080 \
  --memory=512Mi \
  --cpu=1 \
  --min-instances=0 \
  --max-instances=10 \
  --quiet

# -------------------------------------------------------
# Output the service URL
# -------------------------------------------------------
SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" \
  --region="$REGION" \
  --format="value(status.url)")

echo ""
echo "==========================================="
echo "  Deployment Complete"
echo "==========================================="
echo ""
echo "  Service URL: $SERVICE_URL"
echo "  Image:       $TAG"
echo ""
echo "  Test with:"
echo "    curl ${SERVICE_URL}/health"
echo ""
