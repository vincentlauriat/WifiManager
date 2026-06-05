import SwiftUI

@main
struct WifiManagerApp: App {
    @StateObject private var monitor = WiFiMonitor()
    @StateObject private var locationManager = LocationProfileManager()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(monitor)
                .environmentObject(locationManager)
        } label: {
            MenuBarIconView(status: monitor.status)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(monitor)
                .environmentObject(locationManager)
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
        case .disconnected: return "wifi.slash"
        case .hotspot, .wifi: return "wifi"
        }
    }
}
