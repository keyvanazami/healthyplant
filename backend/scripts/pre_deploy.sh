#!/bin/bash
set -euo pipefail

# -----------------------------------------------------------
# pre_deploy.sh
# Packages Cloud Function source code into zips, uploads them
# to GCS, and builds + pushes the Cloud Run Docker image.
# Run this BEFORE terraform apply.
# -----------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID env var}"
REGION="${GCP_REGION:-us-central1}"
APP_NAME="${APP_NAME:-healthyplant}"

FUNCTIONS_BUCKET="${PROJECT_ID}-${APP_NAME}-functions-src"

echo "=== Pre-deploy: project=$PROJECT_ID region=$REGION ==="

# -----------------------------------------------------------
# 1. Create the functions source bucket if it doesn't exist
# -----------------------------------------------------------
echo ""
echo "--- Ensuring functions source bucket exists: $FUNCTIONS_BUCKET ---"
if ! gsutil ls -b "gs://$FUNCTIONS_BUCKET" &>/dev/null; then
    gsutil mb -l "$REGION" -p "$PROJECT_ID" "gs://$FUNCTIONS_BUCKET"
    echo "Created bucket $FUNCTIONS_BUCKET"
else
    echo "Bucket $FUNCTIONS_BUCKET already exists"
fi

# -----------------------------------------------------------
# 2. Package and upload Cloud Function source zips
# -----------------------------------------------------------
FUNCTIONS_DIR="$BACKEND_DIR/functions"

for func_dir in "$FUNCTIONS_DIR"/*/; do
    func_name=$(basename "$func_dir")
    zip_file="/tmp/${func_name}.zip"

    echo ""
    echo "--- Packaging function: $func_name ---"

    # Create zip from the function directory
    (cd "$func_dir" && zip -r "$zip_file" . -x '*.pyc' '__pycache__/*' '.git/*')

    # Upload to GCS
    echo "Uploading $zip_file to gs://$FUNCTIONS_BUCKET/$func_name.zip"
    gsutil cp "$zip_file" "gs://$FUNCTIONS_BUCKET/$func_name.zip"

    # Cleanup
    rm -f "$zip_file"
    echo "Done: $func_name"
done

# -----------------------------------------------------------
# 3. Build and push Docker image for Cloud Run
# -----------------------------------------------------------
echo ""
echo "--- Building and pushing Cloud Run API image ---"
IMAGE="gcr.io/$PROJECT_ID/${APP_NAME}-api:latest"

(cd "$BACKEND_DIR/api" && gcloud builds submit --tag "$IMAGE" --project "$PROJECT_ID" --quiet)

echo ""
echo "=== Pre-deploy complete ==="
echo "  Functions uploaded to: gs://$FUNCTIONS_BUCKET/"
echo "  Docker image pushed:   $IMAGE"
echo ""
echo "You can now run: cd ../terraform && terraform apply"
