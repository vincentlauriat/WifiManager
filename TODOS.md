# TODOS — WifiManager

## Backlog — v1.2+

- [ ] Real download speed test via URLSession against a dedicated endpoint
- [ ] 24-hour RSSI and latency history chart (SwiftUI Charts)
- [ ] CSV export of metrics (RSSI, latency, speed) for a chosen time range
- [ ] Multi-interface support (multiple WiFi adapters)
- [ ] Global keyboard shortcut to open the popover

## In progress — v1.2

- [x] System notifications: alert on connection loss and on hotspot switch (localized, opt-in toggles)
- [x] Localize notification + connection-error strings via `Strings`
- [x] Request notification permission once at launch (was per-alert)
- [x] Consolidate to a single `NWPathMonitor` (removes dual-monitor path race)
- [x] Dynamic version string in About tab

## Done — v1.1 (released 2026-06-12)

### Features
- [x] Launch at login via SMAppService (macOS 13+)
- [x] WiFi global toggle (enable/disable via CWInterface.setPower)
- [x] Guide to replace the native WiFi system icon (System Settings → Control Center)
- [x] SSID grouping in the network list (AP count badge)
- [x] Auto-reconnect when disconnected (configurable interval, disabled when WiFi is off)
- [x] Searching animation (menu bar icon pulse + symbolEffect badge in popover)
- [x] Event-driven network detection via CWEventDelegate — instant state updates
- [x] Poll timer fixed: now a one-shot fallback that respects the Preferences interval
- [x] Menu bar icon fix: replaced non-existent globe.slash with wifi.slash
- [x] Menu bar icon: wifi / personalhotspot / wifi.slash instead of globe

### Release pipeline
- [x] `Scripts/release.sh` — build Release → codesign Developer ID + Hardened Runtime → notarise Apple → staple → DMG Finder layout → Sparkle EdDSA → appcast.xml
- [x] `Scripts/make-dmg-background.swift` — fond DMG 540×380 avec flèche app → Applications
- [x] `Scripts/fetch-sparkle-tools.sh` — téléchargement one-time des outils Sparkle
- [x] `.sparkle-tools` symlink → MarkdownViewer/.sparkle-tools (partagé)
- [x] Notary profile `AppliMacVincentGithub` (keychain), clé EdDSA `MarkdownViewer` account
- [x] Release GitHub v1.1.0 : DMG notarisé + appcast.xml poussé sur main

## Done — v1.0 (released 2026-06-05)

- [x] Color-coded menu bar icon (red / orange / green)
- [x] Connection status detection via CWWiFiClient + NWPathMonitor
- [x] RSSI, latency, link speed, SNR metrics with animated bars
- [x] Per-use quality scores (email, browsing, video call, gaming, streaming)
- [x] Reconnect (disassociate + scan + re-associate)
- [x] Network scanner with available networks list
- [x] Join a network (open or secured with inline password prompt)
- [x] Personal hotspot detection via NWPath.isExpensive
- [x] Location profiles (CoreLocation + UserDefaults JSON)
- [x] Preferences window (General / Locations / About)
- [x] XcodeGen project structure (project.yml)
- [x] FR / EN language switcher in Preferences
- [x] Sparkle 2 auto-update (EdDSA key generated, appcast-ready)
- [x] English README with badges, roadmap, build instructions
- [x] Public GitHub repository (https://github.com/vincentlauriat/WifiManager)
- [x] Popover + Preferences screenshots in README
