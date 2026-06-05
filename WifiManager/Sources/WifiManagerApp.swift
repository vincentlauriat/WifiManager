import SwiftUI
import Sparkle

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
        } label: {
            MenuBarIconView(status: monitor.status)
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

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(systemName: symbolName)
                .symbolRenderingMode(.hierarchical)

            // SF Symbols in MenuBarExtra are forced to template (monochrome) by macOS.
            // A SwiftUI shape bypasses that pipeline and preserves its fill color.
            Circle()
                .fill(dotColor)
                .frame(width: 6, height: 6)
                .offset(x: 2, y: 2)
        }
    }

    private var symbolName: String {
        switch status {
        case .disconnected:     return "globe.slash"
        case .hotspot, .wifi:   return "globe"
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
