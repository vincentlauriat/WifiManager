import SwiftUI

struct StatusHeaderView: View {
    @EnvironmentObject var monitor: WiFiMonitor
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        HStack(spacing: 10) {
            statusBadge

            VStack(alignment: .leading, spacing: 2) {
                if let m = monitor.metrics {
                    Text(m.ssid)
                        .font(.headline)
                    HStack(spacing: 4) {
                        if m.isExpensive {
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
                            Text("· \(updatedLabel(updated))")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                } else {
                    Text(lang.s.notConnected)
                        .font(.headline)
                    Text(lang.s.noActiveWifi)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                Task { await monitor.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(lang.s.refresh)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var statusBadge: some View {
        ZStack {
            Circle()
                .fill(monitor.status.iconColor.opacity(0.15))
                .frame(width: 36, height: 36)
            Image(systemName: badgeIcon)
                .font(.system(size: 17))
                .foregroundStyle(monitor.status.iconColor)
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
