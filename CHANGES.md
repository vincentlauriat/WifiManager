# Changelog — WifiManager

## [Unreleased]

### Added
- `Scripts/release.sh` : pipeline de release complet (build Release → codesign Developer ID + Hardened Runtime → notarisation Apple → staple → DMG avec layout Finder → signature EdDSA Sparkle → `appcast.xml`)
- `Scripts/make-dmg-background.swift` : génère le fond DMG (flèche app → Applications, fenêtre 540×380)

## [1.1.0] — 2026-06-06

### Added
- WiFi toggle switch in the popover header (enables/disables WiFi via `CWInterface.setPower`)
- Launch at login implemented via `SMAppService` (Preferences → General)
- "System Icon" section in Preferences: guide + button to System Settings → Control Center to hide the native WiFi menu bar icon
- Network list grouped by SSID — only the best-RSSI access point is shown per network, with an AP-count badge when multiple access points share the same SSID
- Configurable auto-reconnect when disconnected (default 20 s, can be disabled) — disabled automatically when WiFi is turned off
- Searching animation: menu bar icon pulses when disconnected with WiFi enabled; popover badge uses `symbolEffect(.pulse)` in the same state
- Event-driven network state detection via `CWEventDelegate` (`linkDidChange`, `ssidDidChange`, `bssidDidChange`, `powerStateDidChange`, `linkQualityDidChange`) — status updates are now instant, not poll-dependent
- Poll timer refactored as a one-shot fallback that re-reads the configured interval from Preferences on each cycle

### Fixed
- Menu bar icon was empty when disconnected: `globe.slash` does not exist as an SF Symbol — replaced with `wifi.slash`
- Menu bar icon: replaced `globe` with `wifi` / `personalhotspot` depending on connection type
- Colored status dot could be clipped outside bounds: replaced `.offset` with padding on the image

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
