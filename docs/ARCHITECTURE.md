# Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                          iOS App (SwiftUI)                          │
│                                                                     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ │
│  │   Home   │ │ Profiles │ │  Garden  │ │ Calendar │ │Assistant │ │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘ │
│       │             │            │             │            │       │
│  ┌────┴─────────────┴────────────┴─────────────┴────────────┴────┐ │
│  │                    ViewModels (MVVM)                           │ │
│  └────┬──────────────────────────────────────────────────────────┘ │
│       │                                                            │
│  ┌────┴──────────────────────────────────────────────────────────┐ │
│  │  Services: APIClient, PlantService, ChatService, AuthService  │ │
│  └────┬──────────────────────────────────────────────────────────┘ │
└───────┼────────────────────────────────────────────────────────────┘
        │  HTTPS / SSE
        ▼
┌───────────────────────────────────────────────────────────────┐
│                 FastAPI Backend (Cloud Run)                    │
│                                                               │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │              Auth Middleware (X-User-ID / JWT)            │ │
│  └──────────────┬───────────────────────────────────────────┘ │
│                 │                                             │
│  ┌──────────────┼──────────────────────────────────────────┐ │
│  │           API Routers (/api/v1)                         │ │
│  │  ┌──────────┐ ┌────────┐ ┌──────────┐ ┌──────────────┐ │ │
│  │  │ profiles │ │ garden │ │ calendar │ │ chat (SSE)   │ │ │
│  │  └────┬─────┘ └───┬────┘ └────┬─────┘ └──────┬───────┘ │ │
│  └───────┼────────────┼──────────┼───────────────┼─────────┘ │
│          │            │          │               │           │
│  ┌───────┴────────────┴──────────┴───────────────┴─────────┐ │
│  │                      Services                            │ │
│  │  ┌───────────────┐ ┌────────────┐ ┌───────────────────┐ │ │
│  │  │ FirestoreServ │ │  AIService │ │  StorageService   │ │ │
│  │  └──────┬────────┘ └─────┬──────┘ └────────┬──────────┘ │ │
│  └─────────┼────────────────┼─────────────────┼────────────┘ │
└────────────┼────────────────┼─────────────────┼──────────────┘
             │                │                 │
             ▼                ▼                 ▼
     ┌──────────────┐ ┌─────────────┐ ┌──────────────────┐
     │   Firestore   │ │ Claude API  │ │  Cloud Storage   │
     │  (NoSQL DB)   │ │ (Anthropic) │ │  (Photo uploads) │
     └──────────────┘ └─────────────┘ └──────────────────┘
```

## iOS Architecture (MVVM)

The iOS app follows the Model-View-ViewModel pattern with SwiftUI.

### Layer Responsibilities

**Models** (`HealthyPlant/Models/`)
- Pure data structs: `PlantProfile`, `CalendarEvent`, `ChatMessage`, `UserSettings`
- `Codable` conformance for JSON serialization with camelCase keys matching the API

**Views** (`HealthyPlant/Views/`)
- Stateless SwiftUI views organized by feature (Home, Profiles, Garden, Calendar, Assistant, Settings)
- Shared UI components in `Components/` (TabBarView, GreenOutlineStyle)
- `ContentView` manages the custom tab bar and switches between the five main views

**ViewModels** (`HealthyPlant/ViewModels/`)
- One view model per feature: `HomeViewModel`, `ProfilesViewModel`, `GardenViewModel`, `CalendarViewModel`, `AssistantViewModel`, `SettingsViewModel`
- Hold `@Published` state, handle user actions, call services

**Services** (`HealthyPlant/Services/`)
- `APIClient` -- Base HTTP client for REST calls and SSE streaming
- `PlantService` -- Profile CRUD operations
- `CalendarService` -- Calendar event fetching and completion
- `ChatService` -- Streaming chat via SSE
- `AuthService` -- Firebase Auth integration, manages auth state via `@EnvironmentObject`
- `NotificationService` -- Firebase Cloud Messaging registration and scheduling
- `ImageUploadService` -- Photo capture/selection and upload to GCS via signed URLs

**App** (`HealthyPlant/App/`)
- `HealthyPlantApp` -- SwiftUI app entry point, injects `AppState` and `AuthService`
- `AppState` -- Shared app-level state accessible via `@EnvironmentObject`
- `ContentView` -- Root view with custom tab bar for five tabs

### Navigation

The app uses a custom `TabBarView` instead of SwiftUI's native `TabView`. The `AppTab` enum defines five cases:

| Tab | View | Icon |
|-----|------|------|
| Home | `HomeView` | `house.fill` |
| Profiles | `ProfilesListView` | `leaf.fill` |
| Garden | `GardenView` | `tree.fill` |
| Calendar | `CalendarView` | `calendar` |
| Assistant | `AssistantView` | `message.fill` |

## Backend Architecture

### Router Organization

All routes live under `/api/v1`. Each router is a self-contained module:

| Router | Prefix | Purpose |
|--------|--------|---------|
| `profiles` | `/api/v1/profiles` | Full CRUD for plant profiles |
| `garden` | `/api/v1/garden` | Read-only garden view (all profiles with AI data) |
| `calendar` | `/api/v1/calendar` | Calendar events by month, mark complete |
| `chat` | `/api/v1/chat` | AI chat with SSE streaming, history CRUD |

### Service Layer

**FirestoreService** -- All database operations. Uses user-scoped subcollections (see Firestore schema below). Handles batch writes for calendar events (respects 500-doc Firestore batch limit).

**AIService** -- Wraps the Anthropic Python SDK. Three AI capabilities:
1. `generate_plant_recommendations()` -- Returns structured JSON with sun, water, and harvest info
2. `generate_calendar_events()` -- Produces a 7-day care schedule based on all user plants
3. `chat_stream()` -- Streams conversational responses with full plant context

**StorageService** -- Generates signed upload URLs for Google Cloud Storage. Clients PUT photos directly to GCS without passing binary through the API.

### Auth Middleware

Every request (except `/health`, `/docs`, `/openapi.json`, `/redoc`) must include authentication. In development, this is a simple `X-User-ID` header. In production, this should verify a Firebase Bearer token and extract the user ID.

The middleware attaches `request.state.user_id` for downstream use by all routers.

## Data Flow Diagrams

### Profile Creation with AI Recommendations

```
iOS App                    Backend                      Claude API        Firestore
   │                          │                             │                │
   │  POST /api/v1/profiles   │                             │                │
   │  {plantType, ageDays...} │                             │                │
   │─────────────────────────>│                             │                │
   │                          │  create_profile()           │                │
   │                          │────────────────────────────────────────────> │
   │                          │                             │   doc created  │
   │                          │ <────────────────────────────────────────────│
   │   201 {profile}          │                             │                │
   │ <────────────────────────│                             │                │
   │                          │                             │                │
   │                          │  (async background task)    │                │
   │                          │  generate_recommendations() │                │
   │                          │────────────────────────────>│                │
   │                          │   {sun, water, harvest}     │                │
   │                          │ <───────────────────────────│                │
   │                          │                             │                │
   │                          │  update_profile(AI fields)  │                │
   │                          │────────────────────────────────────────────> │
   │                          │                             │                │
   │  GET /api/v1/profiles/id │  (next time app fetches)    │                │
   │─────────────────────────>│────────────────────────────────────────────> │
   │  200 {profile + AI data} │ <────────────────────────────────────────────│
   │ <────────────────────────│                             │                │
```

### Chat (SSE Streaming)

```
iOS App                    Backend                    Claude API       Firestore
   │                          │                           │               │
   │  POST /api/v1/chat       │                           │               │
   │  {content: "How often    │                           │               │
   │   should I water..."}    │                           │               │
   │─────────────────────────>│                           │               │
   │                          │  save user message        │               │
   │                          │──────────────────────────────────────────>│
   │                          │  load history + profiles  │               │
   │                          │──────────────────────────────────────────>│
   │                          │                           │               │
   │                          │  chat_stream()            │               │
   │                          │──────────────────────────>│               │
   │                          │                           │               │
   │  SSE: {type:"chunk",     │   text chunk 1            │               │
   │        content:"Based"}  │ <─────────────────────────│               │
   │ <────────────────────────│                           │               │
   │  SSE: {type:"chunk",     │   text chunk 2            │               │
   │        content:" on..."}│ <─────────────────────────│               │
   │ <────────────────────────│                           │               │
   │           ...            │          ...              │               │
   │                          │   stream complete         │               │
   │                          │ <─────────────────────────│               │
   │                          │  save assistant message   │               │
   │                          │──────────────────────────────────────────>│
   │  SSE: {type:"done",      │                           │               │
   │        messageId:"abc"}  │                           │               │
   │ <────────────────────────│                           │               │
```

### Calendar Sync

```
iOS App                    Backend                    Claude API       Firestore
   │                          │                           │               │
   │  GET /api/v1/calendar    │                           │               │
   │  ?month=2026-03          │                           │               │
   │─────────────────────────>│                           │               │
   │                          │  get_events_by_month()    │               │
   │                          │──────────────────────────────────────────>│
   │  200 [events]            │                           │               │
   │ <────────────────────────│                           │               │
   │                          │                           │               │
   │  PUT /api/v1/calendar/   │                           │               │
   │    {event_id}/complete   │                           │               │
   │─────────────────────────>│                           │               │
   │                          │  update_event(completed)  │               │
   │                          │──────────────────────────────────────────>│
   │  200 {updated event}     │                           │               │
   │ <────────────────────────│                           │               │
```

## Firestore Data Model

All user data is stored under user-scoped subcollections for security and isolation.

```
firestore/
└── users/
    └── {userId}/                          # User document (implicit)
        ├── profiles/
        │   └── {profileId}/               # Plant profile
        │       ├── name: string
        │       ├── plantType: string
        │       ├── photoURL: string | null
        │       ├── ageDays: number
        │       ├── plantedDate: string    # "YYYY-MM-DD"
        │       ├── heightFeet: number
        │       ├── heightInches: number
        │       ├── sunNeeds: string | null       # AI-generated
        │       ├── waterNeeds: string | null      # AI-generated
        │       ├── harvestTime: string | null     # AI-generated
        │       ├── aiLastUpdated: string | null   # ISO 8601
        │       ├── createdAt: string              # ISO 8601
        │       └── updatedAt: string              # ISO 8601
        │
        ├── calendar_events/
        │   └── {eventId}/                 # Care event
        │       ├── userId: string
        │       ├── profileId: string      # FK to profiles
        │       ├── plantName: string
        │       ├── date: string           # "YYYY-MM-DD"
        │       ├── eventType: string      # "needs_water" | "needs_sun" | "needs_treatment"
        │       ├── description: string
        │       ├── completed: boolean
        │       └── createdAt: string      # ISO 8601
        │
        └── chat_messages/
            └── {messageId}/               # Chat message
                ├── userId: string
                ├── role: string           # "user" | "assistant"
                ├── content: string
                └── timestamp: string      # ISO 8601
```

### Firestore Indexes Required

- `calendar_events`: composite index on `(date ASC)` with range filters on `date`
- `calendar_events`: composite index on `(profileId, date, eventType)` for deduplication queries
- `chat_messages`: single-field index on `timestamp DESC` for history retrieval

## AI Integration Details

### Model

The app uses **Claude claude-sonnet-4-20250514** (`claude-sonnet-4-20250514`) via the Anthropic Python SDK.

### Recommendation Engine

When a plant profile is created, a background `asyncio` task calls `AIService.generate_plant_recommendations()`. The prompt includes the plant type, age, and planting date. Claude returns a structured JSON object with three fields (`sun_needs`, `water_needs`, `harvest_time`), which are written back to the profile document. This is fire-and-forget -- the profile is returned to the client immediately, and AI fields are populated asynchronously.

### Calendar Event Generation

`AIService.generate_calendar_events()` takes all user plant profiles plus the current date and asks Claude to produce a 7-day care schedule. Each event is validated against a set of allowed types (`needs_water`, `needs_sun`, `needs_treatment`) before being persisted. The service uses deduplication checks (`event_exists()`) to avoid creating duplicate events.

### Chat Assistant

The chat uses **SSE (Server-Sent Events)** for real-time streaming. The system prompt includes all of the user's plant profiles so Claude can give personalized advice. Conversation history (last 20 messages) is loaded from Firestore for context continuity. Messages are guaranteed to alternate between user and assistant roles per Claude's API requirements (consecutive same-role messages are merged automatically).

The SSE stream emits three event types:
- `chunk` -- A piece of the response text as it arrives
- `done` -- Stream complete, includes the saved `messageId`
- `error` -- An error occurred during generation
