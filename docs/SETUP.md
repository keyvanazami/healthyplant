# Setup Guide

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Xcode | 15.0+ | iOS development, Swift 5.9 |
| XcodeGen | 2.38+ | Generate `.xcodeproj` from `project.yml` |
| Python | 3.12+ | Backend runtime |
| Google Cloud SDK (`gcloud`) | Latest | GCP authentication, deployment |
| Terraform | 1.5+ | Infrastructure provisioning |
| Node.js | 18+ | Firebase CLI tools (optional, for local emulators) |
| Firebase CLI | Latest | Push notifications setup, emulators |

## iOS Setup

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/healthyplant.git
cd healthyplant
```

### 2. Generate the Xcode Project

The iOS app uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode project from `project.yml`. This keeps the `.xcodeproj` out of version control and avoids merge conflicts.

```bash
# Install XcodeGen if you don't have it
brew install xcodegen

# Generate the project
cd HealthyPlant
xcodegen generate
```

This produces `HealthyPlant.xcodeproj` based on the spec in `project.yml`.

### 3. Open in Xcode

```bash
open HealthyPlant.xcodeproj
```

### 4. Resolve Swift Package Dependencies

Xcode should automatically resolve the two SPM dependencies on first open:
- **Lottie** (4.4.0+) -- Animations for the home screen cactus
- **Firebase iOS SDK** (10.22.0+) -- FirebaseAuth and FirebaseMessaging

If they don't resolve automatically, go to **File > Packages > Resolve Package Versions**.

### 5. Add GoogleService-Info.plist

Firebase requires a configuration file for your specific project:

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create one)
3. Add an iOS app with bundle ID `com.healthyplant.app`
4. Download `GoogleService-Info.plist`
5. Place it in `HealthyPlant/HealthyPlant/Resources/`

> **Important**: This file contains project-specific keys and should not be committed to version control. It is typically added to `.gitignore`.

### 6. Configure the API Base URL

The `APIClient` service needs to know where the backend is running. For local development, the default is typically `http://localhost:8080`. Check `Services/APIClient.swift` for the base URL configuration and update it if your backend runs on a different host or port.

### 7. Build and Run

1. Select the **HealthyPlant** scheme
2. Choose a simulator: **iPhone 15** (iOS 17.0+)
3. Press **Cmd+R** to build and run

## Backend Setup

### 1. Create a GCP Project

```bash
# Create project (or use an existing one)
gcloud projects create healthy-plant-dev --name="Healthy Plant Dev"
gcloud config set project healthy-plant-dev

# Enable required APIs
gcloud services enable \
  firestore.googleapis.com \
  run.googleapis.com \
  storage.googleapis.com \
  cloudbuild.googleapis.com
```

### 2. Set Up Firestore

```bash
# Create a Firestore database in Native mode
gcloud firestore databases create --location=us-central1
```

Or use Terraform:

```bash
cd backend/terraform
terraform init
terraform apply
```

### 3. Set Up a Service Account (for Local Development)

```bash
# Create a service account
gcloud iam service-accounts create healthy-plant-api \
  --display-name="Healthy Plant API"

# Grant roles
gcloud projects add-iam-policy-binding healthy-plant-dev \
  --member="serviceAccount:healthy-plant-api@healthy-plant-dev.iam.gserviceaccount.com" \
  --role="roles/datastore.user"

gcloud projects add-iam-policy-binding healthy-plant-dev \
  --member="serviceAccount:healthy-plant-api@healthy-plant-dev.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"

# Download key file
gcloud iam service-accounts keys create backend/api/service-account.json \
  --iam-account=healthy-plant-api@healthy-plant-dev.iam.gserviceaccount.com
```

> **Important**: Never commit `service-account.json` to version control. Add it to `.gitignore`.

### 4. Configure Environment Variables

Create a `.env` file in `backend/api/`:

```bash
# backend/api/.env

# Required -- Anthropic API key for AI features
ANTHROPIC_API_KEY=sk-ant-api03-...

# Required -- GCP project ID
GCP_PROJECT_ID=healthy-plant-dev

# Required -- GCS bucket for photo uploads
GCS_BUCKET_NAME=healthy-plant-uploads

# Required for local dev -- path to service account key
GOOGLE_APPLICATION_CREDENTIALS=./service-account.json
```

### 5. Install Dependencies and Run Locally

```bash
cd backend/api

# Create and activate virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run the API server
uvicorn main:app --reload --port 8080
```

The API is now available at `http://localhost:8080`. Visit `http://localhost:8080/docs` for the interactive Swagger UI.

### 6. Verify It Works

```bash
# Health check
curl http://localhost:8080/health

# Create a profile (requires X-User-ID header)
curl -X POST http://localhost:8080/api/v1/profiles \
  -H "Content-Type: application/json" \
  -H "X-User-ID: test-user-1" \
  -d '{
    "name": "My Tomato",
    "plantType": "Cherry Tomato",
    "ageDays": 14,
    "plantedDate": "2026-03-01",
    "heightFeet": 0,
    "heightInches": 6
  }'
```

### 7. Deploy to Cloud Run

```bash
# Build and deploy using gcloud
cd backend/api

gcloud run deploy healthy-plant-api \
  --source . \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY,GCP_PROJECT_ID=$GCP_PROJECT_ID,GCS_BUCKET_NAME=$GCS_BUCKET_NAME"
```

Or use Terraform for a repeatable deployment:

```bash
cd backend/terraform
terraform apply -var="anthropic_api_key=$ANTHROPIC_API_KEY"
```

## Environment Variables Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `ANTHROPIC_API_KEY` | Yes | -- | Anthropic API key for Claude. AI features return defaults if unset. |
| `GCP_PROJECT_ID` | Yes | -- | Google Cloud project ID for Firestore and Cloud Storage |
| `GCS_BUCKET_NAME` | No | `healthy-plant-uploads` | GCS bucket name for plant photo uploads |
| `GOOGLE_APPLICATION_CREDENTIALS` | Local only | -- | Path to service account JSON key file. Not needed on Cloud Run (uses attached SA). |
| `PORT` | No | `8080` | Port for the uvicorn server. Cloud Run sets this automatically. |

## Troubleshooting

**Xcode: "Missing package product"**
Run **File > Packages > Reset Package Caches** then **Resolve Package Versions**.

**Backend: "ANTHROPIC_API_KEY not set"**
AI features will still work but return generic defaults. Set the key in your `.env` file for real AI responses.

**Backend: Firestore permission denied**
Ensure your service account has the `roles/datastore.user` role and `GOOGLE_APPLICATION_CREDENTIALS` points to the correct key file.

**Backend: "Failed to initialize Storage client"**
The storage service logs a warning but does not crash. Photo upload features will be unavailable until GCS credentials are configured.
