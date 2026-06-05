import SwiftUI

struct StatusHeaderView: View {
    @EnvironmentObject var monitor: WiFiMonitor

    var body: some View {
        HStack(spacing: 10) {
            statusBadge

            VStack(alignment: .leading, spacing: 2) {
                if let m = monitor.metrics {
                    Text(m.ssid)
                        .font(.headline)
                    HStack(spacing: 4) {
                        if m.isExpensive {
                            Label("Partage de connexion", systemImage: "personalhotspot")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        } else {
                            Text(monitor.status.statusLabel)
                                .font(.caption)
                                .foregroundStyle(monitor.status.iconColor)
                        }
                        if let ch = m.channel {
                            Text("· Canal \(ch)")
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
                    Text("Non connecté")
                        .font(.headline)
                    Text("Aucun réseau WiFi actif")
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
            .help("Actualiser")
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
        if secs < 10 { return "à l'instant" }
        if secs < 60 { return "il y a \(secs) s" }
        return "il y a \(secs / 60) min"
    }
}
