# Architecture — WifiManager

## Overview

```
┌─────────────────────────────────────────────────────┐
│                  macOS Menu Bar                      │
│         (red / orange / green icon)                  │
└─────────────────────┬───────────────────────────────┘
                      │ click
                      ▼
┌─────────────────────────────────────────────────────┐
│       WifiManager.app  (SwiftUI, macOS 14+)          │
│                                                      │
│  ┌──────────────────────────────────────────────┐    │
│  │            MenuBarExtra (.window)            │    │
│  │  ┌────────────────────────────────────────┐  │    │
│  │  │           MenuBarView                  │  │    │
│  │  │  ├─ StatusHeaderView  (SSID + badge)   │  │    │
│  │  │  ├─ MetricsView       (RSSI, latency)  │  │    │
│  │  │  ├─ UsageScoresView   (email, video…)  │  │    │
│  │  │  ├─ Actions           (reconnect, scan)│  │    │
│  │  │  └─ NetworkListView   (available nets) │  │    │
│  │  └────────────────────────────────────────┘  │    │
│  └──────────────────────────────────────────────┘    │
│                                                      │
│  ┌──────────────────────────────────────────────┐    │
│  │            Services (@MainActor)             │    │
│  │  ┌─────────────────┐  ┌──────────────────┐  │    │
│  │  │   WiFiMonitor   │  │LocationProfileMgr│  │    │
│  │  │  ObservableObject│  │ ObservableObject │  │    │
│  │  └────────┬────────┘  └──────────────────┘  │    │
│  │           │                                  │    │
│  │  ┌────────┴────────────────────────────────┐ │    │
│  │  │  CoreWLAN      Network    CoreLocation  │ │    │
│  │  │  CWWiFiClient  NWPathMonitor  CLLocation│ │    │
│  │  └─────────────────────────────────────────┘ │    │
│  └──────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
```

## Tech Stack

| Layer | Choice | Reason |
|---|---|---|
| Language | Swift 5.9+ | Native macOS |
| UI | SwiftUI + MenuBarExtra | Native macOS 14+ menu bar |
| WiFi | CoreWLAN (CWWiFiClient) | Official Apple API for SSID, RSSI, scan, association |
| Connectivity | Network.framework (NWPathMonitor) | Hotspot detection via `isExpensive`, path changes |
| Location | CoreLocation (CLLocationManager) | Location-based profiles |
| Persistence | UserDefaults (JSON) | Serialized location profiles |
| Preferences | @AppStorage | Simple settings |
| Concurrency | async/await + @MainActor | Swift Concurrency, thread safety |

## Swift Modules

```
WifiManager/Sources/
├── WifiManagerApp.swift          — @main, MenuBarExtra + Settings scene, menu bar icon
├── AppLanguage.swift             — AppLanguage enum + LanguageManager ObservableObject
├── Strings.swift                 — All localised strings (FR / EN)
├── NetworkStatus.swift           — ConnectionStatus, NetworkQuality, NetworkMetrics
├── UsageProfile.swift            — UsageType (email, web, video, gaming…) + quality scoring
├── LocationProfile.swift         — struct LocationProfile (Codable, CLLocation matching)
│
├── WiFiMonitor.swift             — @MainActor ObservableObject, central service
│                                   CWWiFiClient + NWPathMonitor + 30 s polling
│                                   reconnect(), scanNetworks(), connect(to:password:)
├── NetworkQualityChecker.swift   — actor: HEAD latency test to apple.com, 30 s cache
│                                   computeUsageScores() → [UsageType: NetworkQuality]
├── ConnectionTypeDetector.swift  — Isolated NWPathMonitor, exposes isExpensive / isConnected
├── LocationProfileManager.swift  — @MainActor ObservableObject, CLLocationManagerDelegate
│                                   CRUD profiles (UserDefaults JSON)
│
├── MenuBarView.swift             — Main popover layout (310 pt)
├── StatusHeaderView.swift        — Colored badge + SSID + channel + timestamp
├── MetricsView.swift             — RSSI / latency / link speed / SNR bars
├── UsageScoresView.swift         — 3×2 grid of color-coded usage icons
├── NetworkListView.swift         — Network list with inline password prompt
└── SettingsView.swift            — TabView: General / Locations / About
```

## Data Flow

### Startup
1. `WifiManagerApp` creates `WiFiMonitor` and `LocationProfileManager` as `@StateObject`
2. `WiFiMonitor.init`: `NWPathMonitor` starts + `Task { await refresh() }` + 30 s `Timer`
3. `refresh()` reads `CWInterface` (SSID, RSSI, noise, link speed), calls `NetworkQualityChecker.measureLatency()`
4. Updates `status`, `metrics`, `usageScores` → SwiftUI re-renders the icon and popover

### Hotspot Detection
1. `ConnectionTypeDetector` maintains a dedicated `NWPathMonitor`
2. `NWPath.isExpensive == true` → expensive connection (iPhone/Android hotspot, cellular)
3. `WiFiMonitor` emits `ConnectionStatus.hotspot(quality:)` instead of `.wifi(quality:)`
4. The icon shows an orange `personalhotspot` badge next to the WiFi symbol

### Latency Measurement
1. `NetworkQualityChecker.measureLatency()`: HEAD request to `apple.com/library/test/success.html`
2. Result cached for 30 s to avoid unnecessary requests
3. Cache invalidated on path change (`NWPathMonitor`) or reconnect
4. Latency feeds `NetworkQuality.from(rssi:latency:)` and `UsageType.quality(latency:download:)`

### Usage Scores
Each `UsageType` defines a `(latencyMs, downloadMbps)` threshold. Score is computed as:
- 0–33% → Poor (red)
- 34–59% → Fair (orange)
- 60–79% → Good (green)
- 80–100% → Excellent (green)

### Scan and Connect
1. `WiFiMonitor.scanNetworks()`: `CWInterface.scanForNetworks()` on `DispatchQueue.global` (blocking ~2–8 s)
2. Networks sorted by descending RSSI, displayed in `NetworkListView`
3. Open network → direct `CWInterface.associate(to:password:"")` 
4. Secured network → inline password prompt → `associate(to:password:pwd)`
5. Known network (in keychain) → `associate(to:password:nil)` (CoreWLAN reads the keychain)

### Location Profiles
1. `LocationProfileManager` manages `[LocationProfile]` persisted as JSON in `UserDefaults`
2. `CLLocationManager` with `distanceFilter: 100 m` and `desiredAccuracy: 100 m`
3. On position change, `matchProfile(to:)` compares against `CLLocation.distance`
4. The active profile is shown in the popover footer

## Notes

- **Non-sandboxed**: required for `CWWiFiClient` to scan and associate without a specific Apple Developer entitlement.
- **`scanForNetworks` is blocking**: executed on `DispatchQueue.global(qos: .userInitiated)` via `withCheckedThrowingContinuation` to avoid blocking the main thread.
- **Latency cache**: latency is measured with a HEAD to apple.com, which measures application-layer RTT (DNS included). Not an ICMP ping, but sufficient to assess perceived quality.
- **`CWNetwork` retroactive Identifiable**: conformance via `@retroactive` (Swift 5.7+) based on `bssid ?? ssid ?? hashValue`. BSSID is unique per access point; SSID may have duplicates.
- **`NWPath.isExpensive`**: reliable for detecting iPhone Personal Hotspot and Android tethering, but returns `false` if the Mac is connected via Ethernet through the phone (rare).
- **Location permission**: not requested at launch. The user enables location profiles in Settings, which triggers the permission prompt.
