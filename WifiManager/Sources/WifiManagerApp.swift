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
        HStack(spacing: 2) {
            Image(systemName: symbolName)
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(status.iconColor)
            if status.isHotspot {
                Image(systemName: "personalhotspot")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.orange)
                    .offset(y: 3)
            }
        }
    }

    private var symbolName: String {
        switch status {
        case .disconnected:         return "globe.slash"
        case .hotspot, .wifi:       return "globe"
        }
    }
}
