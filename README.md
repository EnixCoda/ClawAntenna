# Porter

An iOS app that automatically collects location data in the background and uploads it to a [Supabase](https://supabase.com) backend. Data is buffered locally and synced when connectivity is available, with automatic retry on failure.

## Features

- **Background location tracking** — Uses Significant Location Change Monitoring (~500m threshold) for battery-efficient collection that survives app suspension
- **Offline buffering** — Location records are persisted locally with SwiftData and uploaded when ready
- **Automatic retry** — Failed uploads are reattempted up to 5 times with attempt tracking
- **Idempotent uploads** — UUID primary keys prevent duplicate records on the server
- **Secure credential storage** — Supabase API key is stored in the iOS Keychain
- **Dashboard UI** — Real-time view of tracking status, pending/uploaded/failed record counts, and last known location
- **Permission onboarding** — Guided flow to obtain "Always" location permission
- **No custom server** — Uploads directly to Supabase REST API (PostgREST)

## Requirements

- iOS 17.0+
- Xcode 15+
- A [Supabase](https://supabase.com) project (free tier works fine)

## Supabase Setup

Create a `locations` table in your Supabase project's SQL Editor:

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

Enable Row Level Security (RLS) and create an INSERT policy for the service-role key.

## App Configuration

1. Open Porter and complete the location permission onboarding
2. Go to **Settings** (gear icon)
3. Enter your Supabase **Project URL** (e.g. `https://xxxx.supabase.co`)
4. Enter your Supabase **service-role key**
5. Toggle tracking on

The app will start collecting location data and uploading it automatically.

## Architecture

```
iOS App                              Supabase
┌──────────────┐  SwiftData  ┌────────────┐  HTTPS POST  ┌──────────────┐
│ Location     │────────────▶│ Location   │─────────────▶│ POST         │
│ Manager      │             │ Records    │              │ /rest/v1/    │
│ (CoreLocation│             │ (pending → │              │  locations   │
│  delegate)   │             │  uploaded) │              │              │
└──────────────┘             └────────────┘              │ → Postgres   │
                                    │                    └──────────────┘
                             ┌──────┴──────┐
                             │ Upload      │
                             │ Service     │
                             │ (batch POST,│
                             │  retry)     │
                             └─────────────┘
```

## Project Structure

```
Porter/
├── PorterApp.swift              # App entry point, service wiring
├── ContentView.swift            # Routes between onboarding and dashboard
├── Models/
│   └── LocationRecord.swift     # SwiftData model with upload status tracking
├── Services/
│   ├── LocationManager.swift    # CoreLocation wrapper, background monitoring
│   ├── UploadService.swift      # Batch upload to Supabase REST API
│   ├── KeychainHelper.swift     # Secure API key storage
│   └── AppSettings.swift        # User preferences (URL, tracking toggle)
└── Views/
    ├── DashboardView.swift      # Main status screen
    ├── SettingsView.swift       # Supabase connection config
    └── PermissionView.swift     # Location permission onboarding
```

## License

MIT
