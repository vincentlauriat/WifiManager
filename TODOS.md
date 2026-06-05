# TODOS — WifiManager

## Backlog — v1.1

- [ ] Real download speed test via URLSession against a dedicated endpoint
- [ ] System notifications: alert on connection loss or quality degradation
- [ ] 24-hour RSSI and latency history chart (SwiftUI Charts)
- [ ] Launch at login via SMAppService (macOS 13+)

## Backlog — v1.2

- [ ] CSV export of metrics (RSSI, latency, speed) for a chosen time range
- [ ] Multi-interface support (multiple WiFi adapters)
- [ ] Global keyboard shortcut to open the popover
- [ ] Custom app icon (PNG 512×512)

## Done — v1.0

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
