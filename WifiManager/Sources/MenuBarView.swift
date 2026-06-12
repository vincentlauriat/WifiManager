import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var monitor: WiFiMonitor
    @EnvironmentObject var locationManager: LocationProfileManager
    @EnvironmentObject var lang: LanguageManager
    @State private var showNetworkList = false
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(spacing: 0) {
            StatusHeaderView()

            Divider()

            if let m = monitor.metrics {
                MetricsView(metrics: m)
                Divider()
                UsageScoresView(scores: monitor.usageScores)
                Divider()
            }

            actionButtons

            if showNetworkList {
                Divider()
                NetworkListView()
                    .transition(.opacity)
            }

            Divider()

            footer
        }
        .frame(width: 310)
        .animation(.easeInOut(duration: 0.15), value: showNetworkList)
        .animation(.easeInOut(duration: 0.15), value: monitor.metrics != nil)
    }

    private var actionButtons: some View {
        VStack(spacing: 0) {
            MenuActionRow(
                icon: "arrow.trianglehead.2.clockwise.rotate.90",
                label: monitor.isReconnecting ? lang.s.reconnecting : lang.s.reconnect,
                isLoading: monitor.isReconnecting
            ) {
                Task { await monitor.reconnect() }
            }
            .disabled(monitor.isReconnecting || !monitor.isWifiEnabled)

            Divider().padding(.leading, 36)

            MenuActionRow(
                icon: "list.wifi",
                label: lang.s.availableNetworks,
                isLoading: monitor.isScanning,
                trailing: {
                    AnyView(
                        Image(systemName: showNetworkList ? "chevron.up" : "chevron.down")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    )
                }
            ) {
                withAnimation { showNetworkList.toggle() }
                if showNetworkList {
                    Task { await monitor.scanNetworks() }
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 6) {
            if let profile = locationManager.currentProfile {
                Label(profile.name, systemImage: "location.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                openSettings()
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Image(systemName: "gearshape")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(lang.s.preferencesHelp)
            .accessibilityLabel(lang.s.preferencesHelp)

            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(lang.s.quit)
            .accessibilityLabel(lang.s.quit)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
    }
}

private struct MenuActionRow<Trailing: View>: View {
    let icon: String
    let label: String
    let isLoading: Bool
    var trailing: (() -> Trailing)? = nil
    let action: () -> Void

    init(icon: String, label: String, isLoading: Bool, trailing: (() -> Trailing)? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.isLoading = isLoading
        self.trailing = trailing
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 20)
                    .foregroundStyle(.primary)
                Text(label)
                    .font(.callout)
                Spacer()
                if isLoading {
                    ProgressView().scaleEffect(0.6)
                } else if let trailing {
                    trailing()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

extension MenuActionRow where Trailing == EmptyView {
    init(icon: String, label: String, isLoading: Bool, action: @escaping () -> Void) {
        self.init(icon: icon, label: label, isLoading: isLoading, trailing: nil, action: action)
    }
}
