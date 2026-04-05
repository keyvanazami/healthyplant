# HealthyPlant 🌱

An AI-powered plant care companion for iOS. Track your garden, get personalized care recommendations from Claude, chat with a plant expert assistant, and never miss a watering day.

<!-- ![App Screenshot](docs/assets/screenshot.png) -->

## Features

- **Home** -- Animated landing screen with a friendly cactus greeting and quick garden summary
- **Plant Profiles** -- Create detailed profiles for each plant with species, age, height, and photo; AI automatically generates sun, water, and harvest recommendations
- **Garden View** -- Visual overview of all your plants with their AI-generated care info
- **Calendar** -- AI-generated 7-day care schedule with watering, sun, and treatment events you can mark complete
- **AI Assistant** -- Real-time streaming chat with Claude that knows your plants and gives tailored advice
- **Push Notifications** -- Firebase Cloud Messaging reminders for upcoming care tasks

## Tech Stack

| Layer | Technology |
|-------|-----------|
| iOS app | SwiftUI, MVVM, Swift 5.9, iOS 17+ |
| Backend API | Python 3.12, FastAPI, Uvicorn |
| Database | Google Cloud Firestore (user-scoped subcollections) |
| AI | Anthropic Claude API (recommendations + streaming chat) |
| Storage | Google Cloud Storage (signed URL uploads for plant photos) |
| Auth | Firebase Auth (FCM for push notifications) |
| Infrastructure | Terraform (Cloud Run, Firestore, Cloud Functions modules) |
| CI/CD | GitHub Actions (iOS tests, backend deploy to Cloud Run) |
| Project Gen | XcodeGen (`project.yml`) |

## Quick Start

### iOS

```bash
git clone https://github.com/your-org/healthyplant.git
cd healthyplant/HealthyPlant

# Generate Xcode project (requires xcodegen: brew install xcodegen)
xcodegen generate

# Open in Xcode
open HealthyPlant.xcodeproj
```

1. Add your `GoogleService-Info.plist` to `HealthyPlant/HealthyPlant/Resources/`
2. Resolve Swift Package dependencies (Xcode will prompt automatically)
3. Select an iPhone 15 simulator and press **Cmd+R**

### Backend

```bash
cd healthyplant/backend/api

# Create virtual environment
python3 -m venv .venv && source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Set environment variables (or use a .env file)
export ANTHROPIC_API_KEY="sk-ant-..."
export GCP_PROJECT_ID="your-gcp-project"
export GCS_BUCKET_NAME="your-bucket"

# Run locally
uvicorn main:app --reload --port 8080
```

API docs are available at `http://localhost:8080/docs` once running.

## Project Structure

```
healthyplant/
├── HealthyPlant/                  # iOS application
│   ├── project.yml                # XcodeGen project spec
│   └── HealthyPlant/
│       ├── App/                   # App entry point, ContentView, AppState
│       ├── Models/                # Swift data models
│       ├── Views/                 # SwiftUI views by feature
│       │   ├── Home/
│       │   ├── Profiles/
│       │   ├── Garden/
│       │   ├── Calendar/
│       │   ├── Assistant/
│       │   ├── Settings/
│       │   └── Components/
│       ├── ViewModels/            # MVVM view models
│       ├── Services/              # API client, auth, chat, notifications
│       └── Utilities/             # Theme, extensions
├── backend/
│   ├── api/
│   │   ├── main.py               # FastAPI app with lifespan + auth middleware
│   │   ├── routers/              # profiles, garden, calendar, chat
│   │   ├── models/               # Pydantic request/response models
│   │   ├── services/             # Firestore, AI (Claude), GCS storage
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   └── terraform/                # IaC for GCP resources
│       ├── main.tf
│       └── modules/
│           ├── cloud_run/
│           ├── firestore/
│           └── cloud_functions/
├── docs/
│   ├── ARCHITECTURE.md
│   ├── SETUP.md
│   └── API.md
└── .github/workflows/
    ├── ios_tests.yml
    └── backend_deploy.yml
```

## Documentation

- [Architecture](docs/ARCHITECTURE.md) -- System design, data flow, Firestore schema, AI integration
- [Setup Guide](docs/SETUP.md) -- Detailed prerequisites and step-by-step setup
- [API Reference](docs/API.md) -- Full endpoint documentation with examples

## License

Private -- all rights reserved.
