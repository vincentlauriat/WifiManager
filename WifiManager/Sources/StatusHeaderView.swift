import SwiftUI

struct StatusHeaderView: View {
    @EnvironmentObject var monitor: WiFiMonitor
    @EnvironmentObject var lang: LanguageManager
    @AppStorage("showHotspotBadge") private var showHotspotBadge = true

    var body: some View {
        HStack(spacing: 10) {
            statusBadge

            VStack(alignment: .leading, spacing: 2) {
                if let m = monitor.metrics {
                    Text(m.ssid)
                        .font(.headline)
                    HStack(spacing: 4) {
                        if m.isExpensive && showHotspotBadge {
                            Label(lang.s.hotspot, systemImage: "personalhotspot")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        } else {
                            Text(lang.s.statusLabel(for: monitor.status))
                                .font(.caption)
                                .foregroundStyle(monitor.status.iconColor)
                        }
                        if let ch = m.channel {
                            Text("· \(lang.s.channel(ch))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let updated = monitor.lastUpdated {
                            TimelineView(.periodic(from: .now, by: 10)) { _ in
                                Text("· \(updatedLabel(updated))")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                } else if monitor.isWifiEnabled {
                    Text(lang.s.notConnected)
                        .font(.headline)
                    Text(lang.s.noActiveWifi)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(lang.s.wifiOff)
                        .font(.headline)
                    Text(lang.s.wifiOffNote)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 10) {
                Toggle("", isOn: Binding(
                    get: { monitor.isWifiEnabled },
                    set: { _ in Task { await monitor.togglePower() } }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
                .help(monitor.isWifiEnabled ? lang.s.disableWifi : lang.s.enableWifi)
                .accessibilityLabel(monitor.isWifiEnabled ? lang.s.disableWifi : lang.s.enableWifi)

                Button {
                    Task { await monitor.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(lang.s.refresh)
                .accessibilityLabel(lang.s.refresh)
                .disabled(!monitor.isWifiEnabled)
                .opacity(monitor.isWifiEnabled ? 1 : 0.3)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var isSearching: Bool {
        monitor.isWifiEnabled && monitor.status == .disconnected
    }

    private var statusBadge: some View {
        ZStack {
            Circle()
                .fill(monitor.status.iconColor.opacity(0.15))
                .frame(width: 36, height: 36)
            Image(systemName: badgeIcon)
                .font(.system(size: 17))
                .foregroundStyle(monitor.status.iconColor)
                .symbolEffect(.pulse, isActive: isSearching)
        }
    }

    private var badgeIcon: String {
        switch monitor.status {
        case .disconnected: return "wifi.slash"
        case .hotspot: return "personalhotspot"
        case .wifi: return "wifi"
        }
    }

    private func updatedLabel(_ date: Date) -> String {
        let secs = Int(Date().timeIntervalSince(date))
        if secs < 10 { return lang.s.justNow }
        if secs < 60 { return lang.s.secsAgo(secs) }
        return lang.s.minAgo(secs / 60)
    }
}
