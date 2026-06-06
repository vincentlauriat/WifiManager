# WifiManager

![Version](https://img.shields.io/badge/version-1.1.0-blue)
![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-lightgrey)
![Swift](https://img.shields.io/badge/swift-5.9-orange)

A lightweight macOS menu bar app that monitors your WiFi connection quality in real time, distinguishes real networks from iPhone hotspots, and scores connection suitability per use case.

<p align="center">
  <img src="Screenshots/popover.png" width="320" alt="WiFi monitor popover"/>
  &nbsp;&nbsp;
  <img src="Screenshots/settings.png" width="320" alt="Preferences window"/>
</p>

---

## Features

| Feature | Description |
|---|---|
| Live signal metrics | RSSI, latency, link speed, SNR with animated bars |
| Hotspot detection | Automatically detects iPhone Personal Hotspot via `NWPathMonitor` |
| Usage scores | Per-use quality rating: Email, Browsing, Video Call, Gaming, Streaming |
| Network scanner | Lists nearby WiFi networks grouped by SSID; join directly with password prompt |
| WiFi toggle | Enable or disable WiFi from the menu bar popover |
| Auto-reconnect | Automatically retries connection when disconnected (configurable interval) |
| Launch at login | Start WifiManager automatically at login via `SMAppService` |
| Location profiles | Save location/SSID pairs for automatic network suggestions |
| Replace system icon | Guide to hide the native macOS WiFi icon and use WifiManager instead |
| FR / EN interface | Language switcher in Preferences → General |
| Auto-update | Sparkle 2 integration with appcast feed |
| Menu bar icon | Color-coded icon (green / orange / red) with searching pulse animation |

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI (macOS 14+) |
| WiFi scanning & events | CoreWLAN (`CWWiFiClient`, `CWEventDelegate`) |
| Network path | Network framework (`NWPathMonitor`) |
| Location | CoreLocation |
| Auto-update | [Sparkle 2](https://sparkle-project.org) |
| Project generation | [XcodeGen](https://github.com/yonaskolb/XcodeGen) |

---

## Installation

### Requirements

- macOS 14.0 Sonoma or later
- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Build from source

```bash
git clone https://github.com/vincentlauriat/WifiManager.git
cd WifiManager
xcodegen generate
open WifiManager.xcodeproj
```

Or use the build script:

```bash
bash Scripts/build.sh
```

---

## Project Layout

```
WifiManager/
├── project.yml                  # XcodeGen project spec
├── Scripts/
│   └── build.sh                 # Convenience build script
└── WifiManager/
    ├── Info.plist
    ├── Resources/
    │   └── Assets.xcassets/
    └── Sources/
        ├── AppLanguage.swift        # Language enum + LanguageManager
        ├── Strings.swift            # All localised strings (FR/EN)
        ├── WifiManagerApp.swift     # App entry point, Sparkle setup, animated icon
        ├── WiFiMonitor.swift        # CoreWLAN + CWEventDelegate + NWPathMonitor
        ├── NetworkStatus.swift      # ConnectionStatus, NetworkQuality, NetworkMetrics
        ├── NetworkQualityChecker.swift
        ├── ConnectionTypeDetector.swift
        ├── UsageProfile.swift       # UsageType with per-usage quality scoring
        ├── LocationProfile.swift
        ├── LocationProfileManager.swift
        ├── MenuBarView.swift
        ├── StatusHeaderView.swift   # SSID + WiFi toggle + searching animation
        ├── MetricsView.swift
        ├── UsageScoresView.swift
        ├── NetworkListView.swift    # Networks grouped by SSID with AP count badge
        └── SettingsView.swift
```

---

## How Auto-Update Works

WifiManager uses [Sparkle 2](https://sparkle-project.org) for automatic update checks.

1. On launch, Sparkle checks the appcast feed at:
   `https://raw.githubusercontent.com/vincentlauriat/WifiManager/main/appcast.xml`
2. If a newer version is available, a system alert prompts the user.
3. Updates are **not** downloaded automatically (`SUAutomaticallyUpdate = false`).
4. The user can also trigger a check manually via **Preferences → About → Check for Updates…**

To publish a new release, update `appcast.xml` at the repo root with the new version entry and a signed `.dmg` or `.zip` asset.

---

## Roadmap

- [x] Real-time WiFi metrics (RSSI, latency, SNR, link speed)
- [x] Hotspot detection
- [x] Usage quality scores
- [x] Network scanner with password join and SSID grouping
- [x] Location profiles
- [x] FR / EN localisation
- [x] Sparkle auto-update
- [x] Launch at login
- [x] WiFi toggle (enable/disable from menu bar)
- [x] Auto-reconnect when disconnected
- [x] Event-driven state updates (CWEventDelegate)
- [ ] Download speed measurement
- [ ] Notification center alerts on disconnect / hotspot switch
- [ ] 24-hour RSSI and latency history chart
- [ ] iCloud sync for location profiles
- [ ] Menu bar widget (macOS 15+)

---

## License

MIT — see `LICENSE` file (coming soon).
