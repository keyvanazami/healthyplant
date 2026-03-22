# API Reference

## Base URL

| Environment | URL |
|-------------|-----|
| Local | `http://localhost:8080` |
| Staging | `https://healthy-plant-api-staging-xxxxx.run.app` |
| Production | `https://healthy-plant-api-xxxxx.run.app` |

All endpoints are prefixed with `/api/v1` except `/health`.

## Authentication

### Development

Include the user ID directly in a header:

```
X-User-ID: user-123
```

### Production

Pass a Firebase ID token as a Bearer token. The backend middleware verifies the token and extracts the user ID automatically.

```
Authorization: Bearer eyJhbGciOiJSUzI1NiIs...
```

### Unauthenticated Endpoints

The following paths skip authentication:
- `GET /health`
- `GET /docs`
- `GET /openapi.json`
- `GET /redoc`

---

## Endpoints

### Health Check

#### `GET /health`

Returns the service health status.

**Response** `200 OK`
```json
{
  "status": "healthy",
  "service": "healthy-plant-api"
}
```

---

### Profiles

#### `GET /api/v1/profiles`

List all plant profiles for the authenticated user, ordered by creation date (newest first).

**Response** `200 OK`
```json
[
  {
    "id": "abc123",
    "userId": "user-1",
    "name": "My Tomato",
    "plantType": "Cherry Tomato",
    "photoURL": null,
    "ageDays": 14,
    "plantedDate": "2026-03-01",
    "heightFeet": 0,
    "heightInches": 6,
    "sunNeeds": "Full sun, 6-8 hours daily",
    "waterNeeds": "Water deeply every 3-4 days",
    "harvestTime": "Ready in approximately 60 days",
    "aiLastUpdated": "2026-03-08T12:00:00+00:00",
    "createdAt": "2026-03-08T10:30:00+00:00",
    "updatedAt": "2026-03-08T12:00:00+00:00"
  }
]
```

---

#### `POST /api/v1/profiles`

Create a new plant profile. Triggers asynchronous AI recommendation generation.

**Request Body**
```json
{
  "name": "My Tomato",
  "plantType": "Cherry Tomato",
  "ageDays": 14,
  "plantedDate": "2026-03-01",
  "heightFeet": 0,
  "heightInches": 6,
  "photoURL": "https://storage.googleapis.com/bucket/users/u1/plants/tomato.jpg"
}
```

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| `name` | string | Yes | 1-100 chars |
| `plantType` | string | Yes | 1-100 chars |
| `ageDays` | integer | Yes | >= 0 |
| `plantedDate` | string | Yes | YYYY-MM-DD format |
| `heightFeet` | integer | Yes | >= 0 |
| `heightInches` | integer | Yes | 0-11 |
| `photoURL` | string | No | Valid URL |

**Response** `201 Created`
```json
{
  "id": "abc123",
  "userId": "user-1",
  "name": "My Tomato",
  "plantType": "Cherry Tomato",
  "photoURL": null,
  "ageDays": 14,
  "plantedDate": "2026-03-01",
  "heightFeet": 0,
  "heightInches": 6,
  "sunNeeds": null,
  "waterNeeds": null,
  "harvestTime": null,
  "aiLastUpdated": null,
  "createdAt": "2026-03-08T10:30:00+00:00",
  "updatedAt": "2026-03-08T10:30:00+00:00"
}
```

> **Note**: `sunNeeds`, `waterNeeds`, and `harvestTime` are `null` in the initial response. AI recommendations are generated asynchronously and will be populated within a few seconds. Fetch the profile again to see them.

---

#### `GET /api/v1/profiles/{profile_id}`

Get a single plant profile by ID.

**Response** `200 OK` -- Same shape as the profile object above.

**Error Responses**
- `404 Not Found` -- `{"detail": "Profile not found"}`

---

#### `PUT /api/v1/profiles/{profile_id}`

Update an existing plant profile. All fields are optional; only provided fields are updated.

**Request Body**
```json
{
  "name": "Updated Name",
  "heightFeet": 1,
  "heightInches": 2
}
```

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| `name` | string | No | 1-100 chars |
| `plantType` | string | No | 1-100 chars |
| `ageDays` | integer | No | >= 0 |
| `plantedDate` | string | No | YYYY-MM-DD |
| `heightFeet` | integer | No | >= 0 |
| `heightInches` | integer | No | 0-11 |
| `photoURL` | string | No | Valid URL |
| `sunNeeds` | string | No | AI override |
| `waterNeeds` | string | No | AI override |
| `harvestTime` | string | No | AI override |

**Response** `200 OK` -- The full updated profile.

**Error Responses**
- `400 Bad Request` -- `{"detail": "No fields to update"}`
- `404 Not Found` -- `{"detail": "Profile not found"}`

---

#### `DELETE /api/v1/profiles/{profile_id}`

Delete a plant profile and all associated calendar events.

**Response** `204 No Content`

**Error Responses**
- `404 Not Found` -- `{"detail": "Profile not found"}`

---

### Garden

#### `GET /api/v1/garden`

Get all plant profiles formatted for the garden display. Returns the same data as listing profiles, ordered by creation date.

**Response** `200 OK` -- Array of profile objects (same shape as the profiles endpoint).

---

### Calendar

#### `GET /api/v1/calendar?month=YYYY-MM`

Get all care events for a specific month.

**Query Parameters**

| Parameter | Type | Required | Example |
|-----------|------|----------|---------|
| `month` | string | Yes | `2026-03` |

**Response** `200 OK`
```json
[
  {
    "id": "evt-001",
    "userId": "user-1",
    "profileId": "abc123",
    "plantName": "My Tomato",
    "date": "2026-03-22",
    "eventType": "needs_water",
    "description": "Water thoroughly at the base, avoid wetting leaves",
    "completed": false
  },
  {
    "id": "evt-002",
    "userId": "user-1",
    "profileId": "abc123",
    "plantName": "My Tomato",
    "date": "2026-03-24",
    "eventType": "needs_sun",
    "description": "Move to a sunnier spot for at least 6 hours",
    "completed": false
  }
]
```

**Error Responses**
- `400 Bad Request` -- `{"detail": "Invalid month format. Use YYYY-MM (e.g., 2026-03)"}`

---

#### `PUT /api/v1/calendar/{event_id}/complete`

Mark a calendar event as completed.

**Request Body** -- None required.

**Response** `200 OK`
```json
{
  "id": "evt-001",
  "userId": "user-1",
  "profileId": "abc123",
  "plantName": "My Tomato",
  "date": "2026-03-22",
  "eventType": "needs_water",
  "description": "Water thoroughly at the base, avoid wetting leaves",
  "completed": true
}
```

**Error Responses**
- `404 Not Found` -- `{"detail": "Event not found"}`

---

### Chat

#### `POST /api/v1/chat`

Send a message to the AI plant care assistant. The response is streamed via **Server-Sent Events (SSE)**.

**Request Body**
```json
{
  "content": "How often should I water my cherry tomato?"
}
```

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| `content` | string | Yes | 1-2000 chars |

**Response** `200 OK` (Content-Type: `text/event-stream`)

The response is a stream of SSE events. Each event follows the format:

```
data: {"type": "chunk", "content": "Based on"}\n\n
data: {"type": "chunk", "content": " your cherry tomato's"}\n\n
data: {"type": "chunk", "content": " age and needs..."}\n\n
data: {"type": "done", "messageId": "msg-abc123"}\n\n
```

**SSE Event Types**

| Type | Fields | Description |
|------|--------|-------------|
| `chunk` | `content` (string) | A piece of the AI's response text |
| `done` | `messageId` (string) | Stream complete; the full message has been saved to Firestore |
| `error` | `content` (string) | An error occurred during generation |

**Consuming SSE in Swift**

```swift
// The iOS ChatService uses URLSession with a streaming delegate
// to read chunks as they arrive and append them to the UI in real time.
```

---

#### `GET /api/v1/chat/history`

Get the last 50 chat messages for the authenticated user, in chronological order.

**Response** `200 OK`
```json
{
  "messages": [
    {
      "id": "msg-001",
      "userId": "user-1",
      "role": "user",
      "content": "How often should I water my cherry tomato?",
      "timestamp": "2026-03-22T14:30:00+00:00"
    },
    {
      "id": "msg-002",
      "userId": "user-1",
      "role": "assistant",
      "content": "Based on your cherry tomato's age of 14 days...",
      "timestamp": "2026-03-22T14:30:05+00:00"
    }
  ]
}
```

---

#### `DELETE /api/v1/chat/history`

Clear all chat history for the authenticated user.

**Response** `204 No Content`

---

## Common Error Responses

All error responses follow this format:

```json
{
  "detail": "Error message describing what went wrong"
}
```

| Status Code | Meaning |
|-------------|---------|
| `400` | Bad request -- invalid input or missing fields |
| `401` | Unauthorized -- missing or invalid `X-User-ID` header |
| `404` | Not found -- the requested resource does not exist |
| `422` | Validation error -- request body failed Pydantic validation |
| `500` | Internal server error -- unexpected failure |

### Validation Error Format (422)

FastAPI returns detailed validation errors:

```json
{
  "detail": [
    {
      "loc": ["body", "name"],
      "msg": "String should have at least 1 character",
      "type": "string_too_short"
    }
  ]
}
```
