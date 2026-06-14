# Changelog — WifiManager

## [1.2.0] — 2026-06-12

### Added
- **Real download speed test** (opt-in, Preferences → Monitoring): sized download against Cloudflare, shown as a "Download" metric row and feeding the per-use quality scores. Skipped on metered links (hotspots) to preserve data; cached 180 s
- **Location-based auto-switch** (opt-in, Preferences → Locations): the add form can now capture the current position ("Use my current location"), and entering a saved location's radius switches to its preferred SSID
- System notifications on connection loss and on switching to a personal hotspot (toggles in Preferences → Notifications)
- "Show hotspot badge" toggle in Preferences → Monitoring
- Variable-strength WiFi signal glyph in the network list (`wifi` with `variableValue`), `wifi.slash` below −75 dBm
- "Last updated" label now refreshes live via `TimelineView`
- VoiceOver accessibility labels on the icon-only buttons (refresh, WiFi toggle, preferences, quit)
- `WifiManagerTests` target with 20 unit tests (quality scoring, metric math, location matching, Codable)
- `Scripts/release.sh` : pipeline de release complet (build Release → codesign Developer ID + Hardened Runtime → notarisation Apple → staple → DMG avec layout Finder → signature EdDSA Sparkle → `appcast.xml`)
- `Scripts/make-dmg-background.swift` : génère le fond DMG (flèche app → Applications, fenêtre 540×380)

### Changed
- About tab reads the version dynamically from the bundle instead of a hardcoded string
- App version is now a single source of truth in `project.yml` (`CFBundle*` reference `$(MARKETING_VERSION)` / `$(CURRENT_PROJECT_VERSION)`)
- `SWIFT_STRICT_CONCURRENCY` raised from `minimal` to `targeted`
- `computeUsageScores` is now `nonisolated` (removes an actor hop on every refresh)
- Notification permission is requested once at launch instead of at each alert (no more dialog appearing at a random moment)
- Network path is now observed by a single `NWPathMonitor` (in `ConnectionTypeDetector`), which triggers `refresh()` only after `currentPath` is updated — removes the dual-monitor race that could flicker the hotspot badge

### Fixed
- **"Available Networks" showed nothing without Location access**: macOS returns scanned APs with a `nil` SSID until Location is granted, and the `ssid != nil` filter dropped them all into a misleading "No networks found". The list now detects missing authorization (`WiFiMonitor.isLocationAuthorized`) and shows an actionable banner. The banner triggers the **native permission popup** directly when the status is still `.notDetermined`, and falls back to a System Settings link only after a prior denial (macOS forbids re-prompting)
- **Locations feature was cosmetic**: the add form never captured coordinates (so `matches` always returned false) and a match never switched networks — both gaps closed
- Localization: notification titles/bodies and connection-error messages now go through `Strings` (were hardcoded EN / FR respectively, ignoring the language setting)
- `LocationProfileManager` no longer sends `CLLocationManager` across actor boundaries (reads the status synchronously); `startMonitoring` checks `.authorizedAlways` (the only granted status on macOS)
- `UpdaterWrapper` isolated to `@MainActor` (Sparkle's `updater` is main-actor isolated)

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
