# Changelog — WifiManager

## [1.0.0] — 2026-06-05

### Added
- Color-coded menu bar icon (red / orange / green) — bypasses macOS template rendering
- Connection status detection via CWWiFiClient + NWPathMonitor
- RSSI, latency, link speed, SNR metrics with animated bars
- Per-use quality scores (email, browsing, video call, gaming, streaming)
- Reconnect action (disassociate + scan + re-associate)
- Network scanner with available networks list
- Join a network (open or secured with inline password prompt)
- Personal hotspot detection via NWPath.isExpensive
- Location profiles (CoreLocation + UserDefaults JSON)
- Preferences window (General / Locations / About)
- FR / EN language switcher in Preferences
- Sparkle 2 auto-update support (EdDSA key, appcast-ready)
- XcodeGen project structure (project.yml)
