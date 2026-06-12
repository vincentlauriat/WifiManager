# Architecture — WifiManager

## Overview

```
┌─────────────────────────────────────────────────────┐
│                  macOS Menu Bar                      │
│     (wifi / personalhotspot / wifi.slash icon)       │
│     (color dot: green / orange / red, pulsing        │
│      when searching for a network)                   │
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
│  │  │  ├─ StatusHeaderView  (SSID + toggle)  │  │    │
│  │  │  ├─ MetricsView       (RSSI, latency)  │  │    │
│  │  │  ├─ UsageScoresView   (email, video…)  │  │    │
│  │  │  ├─ Actions           (reconnect, scan)│  │    │
│  │  │  └─ NetworkListView   (grouped by SSID)│  │    │
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
│  │  │  CoreWLAN        Network    CoreLocation│ │    │
│  │  │  CWWiFiClient    NWPathMonitor CLLocation│ │    │
│  │  │  CWEventDelegate (event-driven updates) │ │    │
│  │  └─────────────────────────────────────────┘ │    │
│  └──────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
```

## Tech Stack

| Layer | Choice | Reason |
|---|---|---|
| Language | Swift 5.9+ | Native macOS |
| UI | SwiftUI + MenuBarExtra | Native macOS 14+ menu bar |
| WiFi | CoreWLAN (CWWiFiClient + CWEventDelegate) | SSID, RSSI, scan, association, event-driven state changes |
| Connectivity | Network.framework (NWPathMonitor) | Hotspot detection via `isExpensive`, path changes |
| Location | CoreLocation (CLLocationManager) | Location-based profiles |
| Persistence | UserDefaults (JSON) | Serialized location profiles |
| Preferences | @AppStorage | Simple settings |
| Auto-update | Sparkle 2 | EdDSA-signed appcast |
| Concurrency | async/await + @MainActor | Swift Concurrency, thread safety |

## Swift Modules

```
WifiManager/Sources/
├── WifiManagerApp.swift          — @main, MenuBarExtra + Settings scene, animated menu bar icon
├── AppLanguage.swift             — AppLanguage enum + LanguageManager ObservableObject
├── Strings.swift                 — All localised strings (FR / EN)
├── NetworkStatus.swift           — ConnectionStatus, NetworkQuality, NetworkMetrics
├── UsageProfile.swift            — UsageType (email, web, video, gaming…) + quality scoring
├── LocationProfile.swift         — struct LocationProfile (Codable, CLLocation matching)
│
├── WiFiMonitor.swift             — @MainActor ObservableObject, central service
│                                   CWWiFiClient + CWEventDelegate (instant events)
│                                   NWPathMonitor + fallback poll timer
│                                   refresh(), reconnect(), togglePower()
│                                   scanNetworks(), connect(to:password:)
│                                   auto-reconnect timer (configurable interval)
├── NetworkQualityChecker.swift   — actor: HEAD latency test to apple.com, 30 s cache
│                                   computeUsageScores() → [UsageType: NetworkQuality]
├── ConnectionTypeDetector.swift  — Isolated NWPathMonitor, exposes isExpensive / isConnected
├── LocationProfileManager.swift  — @MainActor ObservableObject, CLLocationManagerDelegate
│                                   CRUD profiles (UserDefaults JSON)
│
├── MenuBarView.swift             — Main popover layout (310 pt)
├── StatusHeaderView.swift        — Badge + SSID + WiFi toggle + pulse animation when searching
├── MetricsView.swift             — RSSI / latency / link speed / SNR bars
├── UsageScoresView.swift         — 3×2 grid of color-coded usage icons
├── NetworkListView.swift         — Networks grouped by SSID, AP-count badge, password prompt
└── SettingsView.swift            — TabView: General / Locations / About
```

## Data Flow

### Startup
1. `WifiManagerApp` creates `WiFiMonitor` and `LocationProfileManager` as `@StateObject`
2. `WiFiMonitor.init`: registers `CWEventDelegate` events + starts `NWPathMonitor` + `Task { await refresh() }` + fallback poll timer
3. `refresh()` reads `CWInterface` (SSID, RSSI, noise, link speed), calls `NetworkQualityChecker.measureLatency()`
4. Updates `status`, `metrics`, `usageScores` → SwiftUI re-renders the icon and popover

### Event-Driven State Updates
1. `WiFiMonitor` conforms to `CWEventDelegate` and registers for 5 events via `CWWiFiClient.startMonitoringEvent(with:)`
2. Events fired by macOS → delegate method called on CoreWLAN internal queue → `Task { @MainActor in await self.refresh() }`
3. A `isRefreshing` guard prevents concurrent `refresh()` calls if multiple events arrive simultaneously
4. `NWPathMonitor` provides an additional event source for general connectivity changes
5. The fallback poll timer (default 30 s, configurable) acts as a safety net only

| Event | Trigger |
|---|---|
| `linkDidChange` | WiFi association / disassociation |
| `ssidDidChange` | Network SSID changed (roaming) |
| `bssidDidChange` | Access point changed (roaming) |
| `powerStateDidChange` | WiFi hardware enabled / disabled |
| `linkQualityDidChange` | RSSI or link speed changed |

### WiFi Power Toggle
1. User toggles the switch in `StatusHeaderView`
2. `WiFiMonitor.togglePower()` calls `CWInterface.setPower(_:)`
3. Enabling: waits 1.5 s for the interface to come up, then calls `refresh()`
4. Disabling: immediately clears `status`, `metrics`, cancels auto-reconnect timer
5. `powerStateDidChangeForWiFiInterface` may also fire and trigger a refresh (idempotent)

### Auto-Reconnect
1. After `refresh()` sets `status = .disconnected` with `isWifiEnabled == true`, `scheduleAutoReconnectIfNeeded()` is called
2. A one-shot timer fires after the configured interval (default 20 s; 0 = disabled)
3. On fire: guard checks `isWifiEnabled && .disconnected`, then calls `refresh()` and reschedules if still disconnected
4. Timer is cancelled when `refresh()` results in a connected status or when WiFi is disabled

### Searching Animation
1. `MenuBarIconView` receives `isSearching: Bool = isWifiEnabled && status == .disconnected`
2. A `@State var pulsing: Bool` drives an `easeInOut(duration: 0.8).repeatForever` opacity animation (1.0 → 0.3)
3. Animation stops cleanly when `isSearching` becomes false (transitions back with `.easeInOut(duration: 0.2)`)
4. `StatusHeaderView` badge uses `symbolEffect(.pulse, isActive: isSearching)` (macOS 14 API)

### Hotspot Detection
1. `ConnectionTypeDetector` maintains a dedicated `NWPathMonitor`
2. `NWPath.isExpensive == true` → expensive connection (iPhone/Android hotspot, cellular)
3. `WiFiMonitor` emits `ConnectionStatus.hotspot(quality:)` instead of `.wifi(quality:)`
4. Menu bar icon shows `personalhotspot` symbol; popover badge shows orange hotspot icon

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
2. Networks sorted by descending RSSI; `NetworkListView` groups them by SSID (best RSSI shown, AP count badge if > 1)
3. Open network → direct `CWInterface.associate(to:password:"")` 
4. Secured network → inline password prompt → `associate(to:password:pwd)`
5. Known network (in keychain) → `associate(to:password:nil)` (CoreWLAN reads the keychain)

### Location Profiles
1. `LocationProfileManager` manages `[LocationProfile]` persisted as JSON in `UserDefaults`
2. `CLLocationManager` with `distanceFilter: 100 m` and `desiredAccuracy: 100 m`
3. On position change, `matchProfile(to:)` compares against `CLLocation.distance`
4. The active profile is shown in the popover footer

## Release Pipeline

```
./Scripts/release.sh <version>
        │
        ├─ 1. Sanity check   MARKETING_VERSION in project.yml == <version>
        ├─ 2. xcodegen generate
        ├─ 3. xcodebuild Release  (CODE_SIGNING_ALLOWED=NO)
        ├─ 4. ditto → staging dir  (strip com.apple.provenance xattrs)
        ├─ 5. codesign --options runtime --timestamp
        │       Sparkle.framework/Autoupdate
        │       Sparkle.framework/XPCServices/Downloader.xpc
        │       Sparkle.framework/XPCServices/Installer.xpc
        │       Sparkle.framework/Updater.app
        │       Sparkle.framework
        │       WifiManager.app
        ├─ 6. hdiutil create UDRW  →  AppleScript Finder layout  →  hdiutil convert UDZO
        │       window 540×380, icon size 128, background arrow image
        │       WifiManager.app at (140, 200) · Applications alias at (400, 200)
        ├─ 7. xcrun notarytool submit --wait  (profile: AppliMacVincentGithub)
        ├─ 8. xcrun stapler staple + validate
        ├─ 9. sign_update --account "MarkdownViewer"  →  EdDSA signature
        └─ 10. write appcast.xml
```

| Tool | Role |
|---|---|
| `Scripts/release.sh` | Orchestrates the full pipeline |
| `Scripts/make-dmg-background.swift` | Generates the DMG background PNG (Swift + AppKit, no dependencies) |
| `Scripts/fetch-sparkle-tools.sh` | Downloads Sparkle tools once into `.sparkle-tools/` (symlink → MarkdownViewer) |
| `codesign --options runtime` | Enables Hardened Runtime — required for Apple notarisation |
| `xcrun notarytool` | Apple notarisation — stapled ticket allows Gatekeeper bypass offline |
| `sign_update` | Signs the DMG with the shared EdDSA private key (account `MarkdownViewer` in keychain) |
| `appcast.xml` | Sparkle feed hosted at `raw.githubusercontent.com/…/main/appcast.xml` |

**Prerequisites (one-time per machine):**
- Developer ID Application certificate in login keychain (`KFLACS69T9`)
- Notary profile: `xcrun notarytool store-credentials "AppliMacVincentGithub" --apple-id "vincent@lauriat.fr" --team-id "KFLACS69T9"`
- Sparkle EdDSA private key in keychain (account `MarkdownViewer`) — shared with MarkdownViewer and NetCheck

## Notes

- **Non-sandboxed**: required for `CWWiFiClient` to scan and associate without a specific Apple Developer entitlement.
- **`scanForNetworks` is blocking**: executed on `DispatchQueue.global(qos: .userInitiated)` via `withCheckedThrowingContinuation` to avoid blocking the main thread.
- **Latency cache**: latency is measured with a HEAD to apple.com, which measures application-layer RTT (DNS included). Not an ICMP ping, but sufficient to assess perceived quality.
- **`CWNetwork` retroactive Identifiable**: conformance via `@retroactive` (Swift 5.7+) based on `bssid ?? ssid ?? hashValue`. BSSID is unique per access point; SSID may have duplicates (handled by SSID grouping in `NetworkListView`).
- **`NWPath.isExpensive`**: reliable for detecting iPhone Personal Hotspot and Android tethering, but returns `false` if the Mac is connected via Ethernet through the phone (rare).
- **Location permission**: not requested at launch. The user enables location profiles in Settings, which triggers the permission prompt.
- **`isRefreshing` guard**: prevents overlapping `refresh()` calls when multiple CoreWLAN events fire in rapid succession (e.g., during roaming: `bssidDidChange` + `linkDidChange` + `ssidDidChange`).
