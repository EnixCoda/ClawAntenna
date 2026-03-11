<div align="center">

# 📡 ClawAntenna

**The sensory companion for [OpenClaw](https://github.com/openclaw/openclaw).** 🦞

ClawAntenna gives OpenClaw physical-world awareness — passively collecting sensor data<br>from your iPhone and streaming it to your [Supabase](https://supabase.com) Postgres, where OpenClaw can query it.

<br>

[![Swift](https://img.shields.io/badge/Swift-5.0-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-26+-000000?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-007AFF?style=for-the-badge&logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![Supabase](https://img.shields.io/badge/Supabase-3FCF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![OpenClaw](https://img.shields.io/badge/OpenClaw-compatible-FF6B6B?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHRleHQgeT0iMTgiIGZvbnQtc2l6ZT0iMTgiPvCfpp48L3RleHQ+PC9zdmc+&logoColor=white)](https://github.com/openclaw/openclaw)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

<br>

<p>
  <img src="Homepage.png" width="270" alt="Home — Collectors" />
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="Settings.png" width="270" alt="Settings" />
</p>

**Set it up once. Put your phone in your pocket. Let OpenClaw do the rest.**

<br>

[Quick Start](#-quick-start) · [Data Sources](#-data-sources) · [Why ClawAntenna?](#-why-clawantenna) · [Architecture](#%EF%B8%8F-architecture) · [Roadmap](#%EF%B8%8F-roadmap)

</div>

<br>

## 🦞 Why ClawAntenna?

[OpenClaw](https://github.com/openclaw/openclaw) is the open-source personal AI assistant with 300k+ stars — it lives in your messaging apps and acts as your always-on AI. But it only knows what you *tell* it.

**ClawAntenna bridges the gap between your physical life and your AI.** It silently collects sensor data from your iPhone in the background, uploading everything to a Supabase Postgres database that OpenClaw can query directly — so it can answer questions about your real-world behavior without you ever logging anything manually.

> **OpenClaw knows what you say. ClawAntenna knows what you do.** Together, they know *you*.

```
┌──────────────────────────────────────────────────────────────┐
│                     Your Personal AI Stack                   │
│                                                              │
│  ┌─────────────┐    Supabase     ┌────────────────────────┐  │
│  │  📡 ClawAntenna  │───(Postgres)───▶│  🦞 OpenClaw           │  │
│  │             │                 │                        │  │
│  │  Location   │  "Where was I   │  WhatsApp · Telegram   │  │
│  │  Motion     │   last Tuesday  │  iMessage · Slack      │  │
│  │  Steps      │   at 3pm?"      │  Discord · Signal      │  │
│  │  Health     │                 │  ...20+ channels       │  │
│  │  Battery    │  ──────────▶    │                        │  │
│  │  Network    │  Answers with   │  Skills · Memory       │  │
│  │             │  YOUR data      │  Voice · Canvas        │  │
│  └─────────────┘                 └────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

**What this unlocks:**

| You ask OpenClaw… | ClawAntenna provides… |
|---|---|
| *"Where was I last Tuesday afternoon?"* | GPS location history |
| *"How active was I this week?"* | Step count, distance, activity types |
| *"What's my average commute time?"* | Location patterns + motion data |
| *"Did I sleep well last night?"* | HealthKit sleep analysis |
| *"How much time did I spend at the office?"* | Location dwell times |
| *"Am I more active on weekdays or weekends?"* | Pedometer + activity trends |

OpenClaw can query ClawAntenna's Supabase tables via a [skill](https://docs.openclaw.ai/tools/skills) or its built-in [tool system](https://docs.openclaw.ai/tools) — giving it full SQL access to your physical-world data.

> 💡 **ClawAntenna makes OpenClaw aware of the physical world** — no manual logging, no prompting, just ask.

---

## 📡 Data Sources

| | Collector | Framework | What it captures | Status |
|:---:|-----------|-----------|------------------|:------:|
| 📍 | **Location** | CoreLocation | GPS coordinates, altitude, speed, accuracy | ✅ |
| 🚶 | **Activity** | CoreMotion | Stationary · Walking · Running · Cycling · Driving | 🔜 |
| 👟 | **Pedometer** | CoreMotion | Steps, distance, floors climbed, cadence | 🔜 |
| 🌡️ | **Altimeter** | CoreMotion | Barometric pressure, relative altitude | 🔜 |
| 🔋 | **Battery** | UIKit | Battery level and charging state | 🔜 |
| 📶 | **Connectivity** | Network | Wi-Fi / Cellular / None, connection quality | 🔜 |
| ❤️ | **Health** | HealthKit | Heart rate, energy burned, sleep, workouts | 🔜 |

Each collector runs independently, can be toggled on/off, and uploads to its own Supabase table.

---

## 💡 How It Works

```
┌─────────┐       ┌─────────┐       ┌─────────┐
│         │       │         │       │         │
│  📱     │──────▶│  💾     │──────▶│  ☁️     │
│  Sense  │       │  Buffer │       │  Sync   │
│         │       │         │       │         │
└─────────┘       └─────────┘       └─────────┘
 Collectors        SwiftData         Supabase
 gather data       stores locally    uploads when
 in background     offline-first     connected
```

**1. Sense** — Collectors subscribe to iOS system events (location changes, motion updates, etc.)  
**2. Buffer** — Every data point is persisted to SwiftData immediately, even without connectivity  
**3. Sync** — The upload service batches pending records and POSTs them to your Supabase project  

Records that fail to upload are retried automatically (up to 5 attempts). UUID primary keys guarantee idempotency — you'll never get duplicates.

---

## 🔍 Query Your Life

Once ClawAntenna is running, your Supabase database becomes a queryable journal of your life. Here are some things you can ask:

```sql
-- Where do I spend most of my time?
SELECT
  round(latitude::numeric, 3) AS lat,
  round(longitude::numeric, 3) AS lng,
  count(*) AS visits
FROM locations
GROUP BY lat, lng
ORDER BY visits DESC
LIMIT 10;
```

```sql
-- How many km did I travel last week?
WITH ordered AS (
  SELECT *,
    lag(latitude) OVER (ORDER BY recorded_at) AS prev_lat,
    lag(longitude) OVER (ORDER BY recorded_at) AS prev_lng
  FROM locations
  WHERE recorded_at > now() - interval '7 days'
)
SELECT round(sum(
  earth_distance(ll_to_earth(latitude, longitude), ll_to_earth(prev_lat, prev_lng))
) / 1000) AS km_traveled
FROM ordered
WHERE prev_lat IS NOT NULL;
```

```sql
-- What's my daily step count trend?
SELECT
  date_trunc('day', period_start) AS day,
  sum(steps) AS total_steps
FROM pedometer
GROUP BY day
ORDER BY day DESC
LIMIT 30;
```

> 💡 Your data lives in Postgres — query it with SQL, connect Grafana, pipe into Jupyter, or let [OpenClaw](https://github.com/openclaw/openclaw) query it for you in natural language.

---

## ✨ Features

### 🔋 Battery-first
Collectors use system-triggered events — significant location changes, motion coprocessor updates, HealthKit background delivery — instead of GPS polling or timers. Your battery barely notices.

### 📴 Offline-first
All records are buffered locally with SwiftData. No signal? No problem. ClawAntenna syncs everything when connectivity returns.

### 🔐 Secure by default
API keys live in the iOS Keychain — not in UserDefaults, not in code. HTTPS everywhere. UUID primary keys make every upload idempotent.

### 🧩 Modular collectors
Every data source follows a common `DataCollector` protocol. Adding a new sensor is just conforming to the protocol — the upload pipeline handles the rest.

### ☁️ No server to maintain
Uploads directly to Supabase's REST API (PostgREST). Spin up a free Supabase project and you're done. No custom backend, no infra, no Docker.

### 🔁 Automatic retry
Failed uploads are retried up to 5 times with exponential backoff tracking. Nothing gets silently dropped.

---

## 🚀 Quick Start

### Prerequisites

- **Xcode 26+** and a device running **iOS 26+**
- A free [Supabase](https://supabase.com) project

### 1. Set up Supabase

<details>
<summary><strong>📋 Click to expand — SQL schema for all tables</strong></summary>

<br>

Run this in your Supabase project's **SQL Editor**:

```sql
-- 📍 Location data
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

-- 🚶 Motion activity detection
CREATE TABLE activities (
  id UUID PRIMARY KEY,
  activity_type TEXT NOT NULL,
  confidence TEXT NOT NULL,
  started_at TIMESTAMPTZ NOT NULL,
  recorded_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 👟 Pedometer
CREATE TABLE pedometer (
  id UUID PRIMARY KEY,
  steps INT NOT NULL,
  distance DOUBLE PRECISION,
  floors_ascended INT,
  floors_descended INT,
  cadence DOUBLE PRECISION,
  period_start TIMESTAMPTZ NOT NULL,
  period_end TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 🌡️ Barometric altimeter
CREATE TABLE altimeter (
  id UUID PRIMARY KEY,
  pressure DOUBLE PRECISION NOT NULL,
  relative_altitude DOUBLE PRECISION,
  recorded_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 🔋 Battery state
CREATE TABLE battery (
  id UUID PRIMARY KEY,
  level DOUBLE PRECISION NOT NULL,
  state TEXT NOT NULL,
  recorded_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 📶 Network connectivity
CREATE TABLE connectivity (
  id UUID PRIMARY KEY,
  network_type TEXT NOT NULL,
  is_expensive BOOLEAN,
  is_constrained BOOLEAN,
  recorded_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ❤️ Health data
CREATE TABLE health (
  id UUID PRIMARY KEY,
  metric_type TEXT NOT NULL,
  value DOUBLE PRECISION,
  unit TEXT,
  metadata JSONB,
  started_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  recorded_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

Then enable **Row Level Security (RLS)** and create INSERT policies for the service-role key on each table.

</details>

### 2. Clone & build

```bash
git clone https://github.com/EnixCoda/ClawAntenna.git
open ClawAntenna.xcodeproj
```

Select your physical device and hit **⌘R**. (Location services require real hardware.)

### 3. Configure & go

1. Tap **⚙️ Settings** → enter your Supabase **Project URL** and **service-role key**
2. Go back to the home screen and tap any collector to enable it
3. Grant permissions when prompted

**That's it. Put your phone in your pocket. ClawAntenna handles the rest.**

---

## 🏗️ Architecture

```mermaid
flowchart TB
    subgraph Collectors["📱 Collectors"]
        direction LR
        L["📍 Location"]
        M["🚶 Motion"]
        P["👟 Pedometer"]
        B["🔋 Battery"]
        H["❤️ Health"]
    end

    subgraph Local["💾 Local Storage"]
        SD["SwiftData\n(offline buffer)"]
    end

    subgraph Cloud["☁️ Supabase"]
        API["REST API\n(PostgREST)"]
        DB["PostgreSQL\nlocations · activities\npedometer · health · …"]
    end

    L & M & P & B & H --> SD
    SD -->|"Batch POST\nRetry · Idempotent"| API
    API --> DB
```

---

## 📂 Project Structure

```
ClawAntenna/
├── ClawAntennaApp.swift          # App entry, service wiring
├── ContentView.swift             # Root view
├── Protocols/
│   ├── DataCollector.swift       # Common collector protocol
│   └── Uploadable.swift          # Upload contract for SwiftData models
├── Collectors/
│   ├── LocationCollector.swift   # GPS via CoreLocation
│   ├── ActivityCollector.swift   # Motion activity via CoreMotion
│   ├── PedometerCollector.swift  # Steps & distance
│   ├── AltimeterCollector.swift  # Barometric pressure
│   ├── BatteryCollector.swift    # Battery level & state
│   ├── ConnectivityCollector.swift # Network type & quality
│   └── HealthCollector.swift     # HealthKit metrics
├── Models/                       # SwiftData models (one per collector)
├── Services/
│   ├── LocationManager.swift     # CoreLocation background monitoring
│   ├── CollectorManager.swift    # Registry for all collectors
│   ├── UploadService.swift       # Batch upload to Supabase REST API
│   ├── KeychainHelper.swift      # Secure credential storage
│   └── AppSettings.swift         # User preferences & config
└── Views/
    ├── DashboardView.swift       # Collector list with status
    ├── CollectorDetailView.swift # Per-collector detail & permissions
    └── SettingsView.swift        # Supabase config & upload queue
```

---

## 🗺️ Roadmap

| Phase | Focus | Description |
|:-----:|-------|-------------|
| **1** | ✅ Architecture | `DataCollector` protocol, modular collector system, generalized upload pipeline |
| **2** | 🚶 Motion & Activity | Activity type detection, pedometer (steps/distance/floors), barometric altitude |
| **3** | 📱 Device Context | Battery level & charging state, network connectivity monitoring |
| **4** | ❤️ Health | HealthKit integration — heart rate, active energy, sleep analysis, workouts (with background delivery) |
| **5** | 🧠 Intelligence | Automatic trip detection, data export (CSV/JSON), dashboard charts & visualizations |

See the full breakdown in the [plan](/plan.md) *(coming soon)*.

---

## 🤝 Contributing

Contributions are welcome! Whether it's a new collector, a bug fix, or improved docs — open an issue or submit a PR.

```bash
# Fork, clone, branch
git checkout -b feat/awesome-collector

# Make changes, then
git commit -m 'Add awesome collector'
git push origin feat/awesome-collector
```

**Ideas for contributions:**
- 🆕 New collector (Bluetooth, NFC, screen time, …)
- 🦞 OpenClaw skill for querying ClawAntenna data in natural language
- 📊 Grafana dashboard templates for the Supabase data
- 🧪 Unit tests for upload retry logic
- 📱 Widget extension for quick status glance

---

## 📄 License

[MIT](LICENSE) — use it however you want.

---

<div align="center">

<br>

**ClawAntenna is free and open source.**<br>
If you find it useful, a ⭐ on GitHub goes a long way.

<br>

Made with Swift · SwiftUI · SwiftData · Supabase<br>
Pairs beautifully with [🦞 OpenClaw](https://github.com/openclaw/openclaw)

</div>
