# Porter — iOS Personal Data Porting App

## Problem Statement

Build an iOS app that automatically collects personal data (starting with location) and reports it to a remote database. Data collection and reporting must happen in the background without user interaction. The system should be resilient to network failures by buffering data locally.

## Proposed Approach

**iOS App (Swift/SwiftUI):**
- Use Core Location's **Significant Location Change Monitoring** for battery-efficient background location tracking (~500m movement threshold, wakes app from suspension)
- Buffer collected data in a local store (SwiftData) before uploading
- Use `URLSession` for upload to Supabase REST API
- Simple dashboard UI showing status, recent data points, and settings

**Backend (Supabase — no custom server):**
- Use Supabase's hosted Postgres + auto-generated REST API (PostgREST)
- iOS app POSTs location records directly to `https://<project>.supabase.co/rest/v1/locations`
- Auth via Supabase API key (`apikey` header) + Row Level Security (RLS) with a service-role key for writes
- No custom server code needed — Supabase handles ingestion, storage, and querying
- Free tier: 500MB database, 50K monthly API requests (more than enough for personal use)
- Built-in dashboard (Table Editor) for viewing/querying data

**Auth Strategy:**
- Supabase service-role key for writes (bypasses RLS, kept secret on-device)
- iOS app stores the key in Keychain; sends as `apikey` + `Authorization: Bearer <service_role_key>` headers
- RLS policies lock the table down — only service-role key can insert
- Optional: add a read-only `anon` key policy for a future web dashboard

---

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│                  iOS App (Porter)                │
│                                                  │
│  ┌──────────────┐   ┌──────────────────────┐    │
│  │ Location      │──▶│ DataStore (SwiftData) │    │
│  │ Manager       │   │  - LocationRecord     │    │
│  │ (CoreLocation)│   │  - status: pending/   │    │
│  └──────────────┘   │    uploaded/failed     │    │
│                      └──────────┬───────────┘    │
│                                 │                 │
│                      ┌──────────▼───────────┐    │
│                      │  UploadService        │    │
│                      │  - URLSession          │    │
│                      │  - Batch upload        │    │
│                      │  - Retry logic         │    │
│                      └──────────┬───────────┘    │
│                                 │                 │
│  ┌──────────────┐              │                 │
│  │ Settings UI   │  Supabase service-role key   │
│  │ - Project URL │              │                 │
│  │ - API Key     │              │                 │
│  │ - Status      │              │                 │
│  └──────────────┘              │                 │
└─────────────────────────────────┼─────────────────┘
                                  │ HTTPS POST
                                  ▼
┌─────────────────────────────────────────────────┐
│              Supabase                            │
│                                                  │
│  POST /rest/v1/locations                         │
│  ├── Validate service-role key (apikey header)   │
│  ├── Parse JSON body (PostgREST auto-maps)       │
│  └── Insert into Postgres `locations` table      │
│                                                  │
│  Table Editor — browse & query data via web UI   │
│  SQL Editor — run custom queries                 │
└─────────────────────────────────────────────────┘
```

---

## Implementation Todos

### Phase 1: iOS Core Infrastructure

#### 1. Project Setup & Capabilities
- Add Background Modes capability: "Location updates"
- Add Location usage description keys to Info.plist (via build settings):
  - `NSLocationAlwaysAndWhenInUseUsageDescription`
  - `NSLocationWhenInUseUsageDescription`
- Create app entitlements file

#### 2. Location Manager Service
- Create `LocationManager` class as `@Observable`
- Wrap `CLLocationManager` with proper delegate handling
- Implement permission request flow ("When In Use" → "Always")
- Implement `startMonitoringSignificantLocationChanges()` for background tracking
- Also support standard location updates when app is in foreground (for immediate feedback)
- Handle all `CLAuthorizationStatus` cases with user guidance
- Store latest location in published properties for UI binding

#### 3. Data Model & Persistence (SwiftData)
- Define `LocationRecord` model:
  - `id: UUID`
  - `latitude: Double`
  - `longitude: Double`
  - `altitude: Double`
  - `horizontalAccuracy: Double`
  - `speed: Double`
  - `timestamp: Date` (when collected)
  - `uploadStatus: UploadStatus` (pending / uploading / uploaded / failed)
  - `uploadAttempts: Int`
  - `lastUploadAttempt: Date?`
- Configure SwiftData `ModelContainer` in the app entry point

#### 4. Upload Service
- Create `UploadService` class
- POST to Supabase REST API: `POST /rest/v1/locations`
  - Headers: `apikey: <service_role_key>`, `Authorization: Bearer <service_role_key>`, `Content-Type: application/json`, `Prefer: return=minimal`
- Implement batch upload: query pending records, serialize to JSON array, POST
- Handle HTTP responses: mark records as uploaded on 2xx, increment retry count on failure
- Implement exponential backoff for retries (max 5 attempts)
- Trigger upload whenever new location data is stored
- Also trigger upload on app launch (flush any buffered data)

#### 5. Settings & Configuration
- Create `AppSettings` using `@AppStorage` / `UserDefaults`:
  - `supabaseURL: String` (e.g. `https://xxxx.supabase.co`)
  - `isTrackingEnabled: Bool`
  - `lastUploadDate: Date?`
- Create `KeychainHelper` utility for secure API key storage (service-role key)

#### 6. App Lifecycle Integration
- Modify `PorterApp.swift`:
  - Initialize `ModelContainer` (SwiftData)
  - Create and inject `LocationManager` and `UploadService` into environment
  - Start/stop location monitoring based on settings
  - Handle `scenePhase` changes (flush data on background transition)

### Phase 2: iOS User Interface

#### 7. Dashboard View (Main Screen)
- Replace default ContentView with a status dashboard:
  - Tracking status indicator (on/off, with toggle)
  - Current/last known location (lat/lon, human-readable if possible)
  - Upload queue status (N pending, N uploaded, N failed)
  - Last successful upload timestamp
  - Location permission status with action button
- Use `NavigationStack` for settings navigation

#### 8. Settings View
- Supabase project URL text field
- Service-role key secure text field
- Toggle for tracking on/off
- Button to manually trigger upload
- Button to clear uploaded records
- Stats: total records, uploaded count, pending count

#### 9. Permission Flow
- Onboarding-style view shown on first launch
- Explains why location permission is needed
- Guides user through "Always Allow" permission
- Shows current permission state with troubleshooting tips

### Phase 3: Supabase Setup

#### 10. Supabase Project & Schema
- Create a new Supabase project
- Create `locations` table via SQL Editor:
  ```sql
  CREATE TABLE locations (
    id UUID PRIMARY KEY,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    altitude DOUBLE PRECISION,
    horizontal_accuracy DOUBLE PRECISION,
    speed DOUBLE PRECISION,
    recorded_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
  );

  CREATE INDEX idx_locations_recorded_at ON locations (recorded_at DESC);
  ```
- Enable RLS on the table
- Create RLS policy: allow INSERT only for service-role key
- Note the project URL and service-role key

### Phase 4: Integration & Polish

#### 11. End-to-End Testing
- Configure iOS app with Supabase project URL and service-role key
- Verify location collection works in foreground
- Verify background location wakes app and records data
- Verify upload succeeds and data appears in Supabase Table Editor
- Verify offline buffering and retry works
- Test app kill + relaunch scenario

#### 12. Reliability & Edge Cases
- Handle location manager errors gracefully
- Handle expired/invalid API key (show user-facing error)
- Handle endpoint unreachable (buffer + retry)
- Prevent duplicate uploads (idempotency via UUID primary key — Postgres `ON CONFLICT DO NOTHING`)
- Add basic logging for debugging (OSLog)

---

## Supabase REST API — Upload Format

Each upload is a `POST /rest/v1/locations` with a JSON array body:

```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "latitude": 37.7749,
    "longitude": -122.4194,
    "altitude": 15.2,
    "horizontal_accuracy": 10.0,
    "speed": 0.0,
    "recorded_at": "2026-03-11T02:30:00Z"
  }
]
```

Headers:
```
apikey: <SUPABASE_SERVICE_ROLE_KEY>
Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>
Content-Type: application/json
Prefer: return=minimal
```

Idempotency: Supabase/Postgres rejects duplicate UUIDs (primary key conflict). Use `Prefer: resolution=ignore-duplicates` header for upsert-like behavior.

---

## Key Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Location strategy | Significant Location Changes | Best battery life; wakes app from suspension; ~500m threshold |
| Local persistence | SwiftData (SQLite) | Native Apple framework; queryable; lightweight |
| Upload mechanism | URLSession + Supabase REST | Simple HTTP POST; no custom server needed |
| Backend | Supabase (hosted Postgres + PostgREST) | Zero server code; free tier; built-in dashboard; real Postgres for querying |
| Auth | Supabase service-role key | Simple; secure with RLS; no OAuth complexity needed for personal app |
| API key storage | iOS Keychain | Secure enclave-backed; persists across reinstalls |
| Idempotency | UUID primary key | Postgres rejects duplicates; safe to retry uploads |
| Data format | JSON over HTTPS | PostgREST natively accepts JSON arrays |

---

## Files to Create/Modify (iOS)

```
Porter/
├── PorterApp.swift                    (MODIFY - add ModelContainer, services, lifecycle)
├── ContentView.swift                  (REPLACE - with dashboard)
├── Models/
│   └── LocationRecord.swift           (NEW - SwiftData model)
├── Services/
│   ├── LocationManager.swift          (NEW - Core Location wrapper)
│   ├── UploadService.swift            (NEW - Supabase upload logic)
│   ├── KeychainHelper.swift           (NEW - secure storage)
│   └── AppSettings.swift              (NEW - user preferences)
├── Views/
│   ├── DashboardView.swift            (NEW - main status screen)
│   ├── SettingsView.swift             (NEW - configuration)
│   └── PermissionView.swift           (NEW - onboarding)
└── Porter.entitlements                (NEW - background modes)
```

## Notes

- iOS 26.2 deployment target means we can use the latest APIs (SwiftData, @Observable, etc.)
- Significant Location Change monitoring is the only background location mode that reliably wakes a terminated app
- The app should handle the case where the user grants "When In Use" but not "Always" — it can still work in foreground but background tracking will be limited
- The iOS app works standalone even without Supabase configured (just buffers data locally)
- No custom server code needed — Supabase PostgREST handles everything
- Future data types (health, screen time, etc.) can be added by extending the data model and creating new Supabase tables
- Supabase free tier limits: 500MB DB, 1GB file storage, 50K monthly API requests, 500MB bandwidth — ample for personal location data
