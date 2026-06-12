import SwiftUI
import Sparkle

@MainActor
final class UpdaterWrapper: ObservableObject {
    let updater: SPUUpdater

    init(controller: SPUStandardUpdaterController) {
        self.updater = controller.updater
    }
}

@main
struct WifiManagerApp: App {
    @StateObject private var monitor = WiFiMonitor()
    @StateObject private var locationManager = LocationProfileManager()
    @StateObject private var langManager = LanguageManager()

    private let updaterController: SPUStandardUpdaterController = {
        let c = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        c.updater.automaticallyChecksForUpdates = true
        c.updater.automaticallyDownloadsUpdates = false
        return c
    }()

    private var updaterWrapper: UpdaterWrapper { UpdaterWrapper(controller: updaterController) }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(monitor)
                .environmentObject(locationManager)
                .environmentObject(langManager)
                .environmentObject(UpdaterWrapper(controller: updaterController))
                .task {
                    // Location → network auto-switch (opt-in). Wired here because it's
                    // the one place both objects are in scope; LocationProfileManager
                    // and WiFiMonitor stay decoupled.
                    locationManager.onProfileEnter = { [weak monitor] profile in
                        guard UserDefaults.standard.bool(forKey: "autoSwitchByLocation") else { return }
                        Task { await monitor?.connect(toSSID: profile.preferredSSID) }
                    }
                }
        } label: {
            MenuBarIconView(
                status: monitor.status,
                isSearching: monitor.isWifiEnabled && monitor.status == .disconnected
            )
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(monitor)
                .environmentObject(locationManager)
                .environmentObject(langManager)
                .environmentObject(UpdaterWrapper(controller: updaterController))
        }
    }
}

private struct MenuBarIconView: View {
    let status: ConnectionStatus
    let isSearching: Bool
    @State private var pulsing = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(systemName: symbolName)
                .padding(.trailing, 4)
                .padding(.bottom, 4)
                .opacity(pulsing ? 0.3 : 1.0)
                .animation(
                    isSearching
                        ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                        : .easeInOut(duration: 0.2),
                    value: pulsing
                )

            // SF Symbols in MenuBarExtra are forced to template (monochrome) by macOS.
            // A SwiftUI shape bypasses that pipeline and preserves its fill color.
            Circle()
                .fill(dotColor)
                .frame(width: 7, height: 7)
        }
        .onAppear { pulsing = isSearching }
        .onChange(of: isSearching) { _, newValue in pulsing = newValue }
    }

    private var symbolName: String {
        switch status {
        case .disconnected:     return "wifi.slash"
        case .hotspot:          return "personalhotspot"
        case .wifi:             return "wifi"
        }
    }

    private var dotColor: Color {
        switch status {
        case .disconnected:         return .red
        case .hotspot:              return .orange
        case .wifi(let q):          return q.color
        }
    }
}
