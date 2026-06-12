import SwiftUI
import Sparkle
import ServiceManagement
import CoreLocation

struct SettingsView: View {
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        TabView {
            GeneralTab()
                .tabItem { Label(lang.s.tabGeneral, systemImage: "gearshape") }
            LocationTab()
                .tabItem { Label(lang.s.tabLocations, systemImage: "location") }
            AboutTab()
                .tabItem { Label(lang.s.tabAbout, systemImage: "info.circle") }
        }
        .frame(width: 420, height: 480)
    }
}

// MARK: - General

private struct GeneralTab: View {
    @AppStorage("pollInterval") private var pollInterval: Double = 30
    @AppStorage("autoReconnectInterval") private var autoReconnectInterval: Double = 20
    @AppStorage("showHotspotBadge") private var showHotspotBadge = true
    @AppStorage("enableSpeedTest") private var enableSpeedTest = false
    @AppStorage("notifyOnDisconnect") private var notifyOnDisconnect = true
    @AppStorage("notifyOnHotspot") private var notifyOnHotspot = true
    @State private var launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        Form {
            Section(lang.s.monitoring) {
                Picker(lang.s.pollIntervalLabel, selection: $pollInterval) {
                    Text("10 s").tag(10.0)
                    Text("30 s").tag(30.0)
                    Text("1 min").tag(60.0)
                    Text("5 min").tag(300.0)
                }
                Toggle(lang.s.hotspotBadge, isOn: $showHotspotBadge)
                Toggle(lang.s.enableSpeedTest, isOn: $enableSpeedTest)
                if enableSpeedTest {
                    Text(lang.s.enableSpeedTestNote)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Section(lang.s.autoReconnect) {
                Picker(lang.s.reconnectIntervalLabel, selection: $autoReconnectInterval) {
                    Text(lang.s.disabled).tag(0.0)
                    Text("10 s").tag(10.0)
                    Text("20 s").tag(20.0)
                    Text("30 s").tag(30.0)
                    Text("1 min").tag(60.0)
                }
            }
            Section(lang.s.notifications) {
                Toggle(lang.s.notifyDisconnect, isOn: $notifyOnDisconnect)
                Toggle(lang.s.notifyHotspot, isOn: $notifyOnHotspot)
            }
            Section(lang.s.startup) {
                Toggle(lang.s.launchAtLogin, isOn: $launchAtLoginEnabled)
                    .onChange(of: launchAtLoginEnabled) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
                        }
                    }
            }
            Section(lang.s.systemIcon) {
                Text(lang.s.systemIconNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button(lang.s.openControlCenter) {
                    NSWorkspace.shared.open(
                        URL(string: "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension")!
                    )
                }
                .buttonStyle(.bordered)
            }
            Section(lang.s.language) {
                Picker(lang.s.language, selection: $lang.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Locations

private struct LocationTab: View {
    @EnvironmentObject var locationManager: LocationProfileManager
    @EnvironmentObject var lang: LanguageManager
    @AppStorage("autoSwitchByLocation") private var autoSwitchByLocation = false
    @State private var showAdd = false
    @State private var newName = ""
    @State private var newSSID = ""
    @State private var capturedLocation: CLLocation?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if locationManager.authorizationStatus == .denied ||
               locationManager.authorizationStatus == .restricted {
                locationWarning
            }

            Toggle(lang.s.autoSwitchByLocation, isOn: $autoSwitchByLocation)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            Divider()

            List {
                ForEach(locationManager.profiles) { profile in
                    ProfileRow(profile: profile)
                }
                .onDelete { locationManager.remove(at: $0) }
            }
            .listStyle(.bordered)

            Divider()

            if showAdd {
                addForm
            }

            HStack {
                Button {
                    withAnimation { showAdd.toggle() }
                    newName = ""; newSSID = ""; capturedLocation = nil
                } label: {
                    Label(
                        showAdd ? lang.s.cancel : lang.s.addLocation,
                        systemImage: showAdd ? "xmark" : "plus"
                    )
                }
                .buttonStyle(.bordered)

                Spacer()

                Text(lang.s.locationsCountLabel(locationManager.profiles.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private var locationWarning: some View {
        HStack(spacing: 8) {
            Image(systemName: "location.slash.fill")
                .foregroundStyle(.orange)
            Text(lang.s.locationDenied)
                .font(.caption)
            Spacer()
            Button(lang.s.openSystemSettings) {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices")!)
            }
            .controlSize(.small)
        }
        .padding(10)
        .background(.orange.opacity(0.1))
    }

    private var addForm: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                TextField(lang.s.locationName, text: $newName)
                    .textFieldStyle(.roundedBorder)
                TextField(lang.s.networkSSID, text: $newSSID)
                    .textFieldStyle(.roundedBorder)
                Button(lang.s.add) {
                    guard !newName.isEmpty, !newSSID.isEmpty else { return }
                    locationManager.add(profile: LocationProfile(
                        name: newName,
                        preferredSSID: newSSID,
                        latitude: capturedLocation?.coordinate.latitude,
                        longitude: capturedLocation?.coordinate.longitude
                    ))
                    newName = ""; newSSID = ""; capturedLocation = nil; showAdd = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(newName.isEmpty || newSSID.isEmpty)
            }

            HStack(spacing: 6) {
                Button {
                    capturedLocation = locationManager.lastKnownLocation
                } label: {
                    Label(
                        capturedLocation != nil ? lang.s.locationCaptured : lang.s.useCurrentLocation,
                        systemImage: capturedLocation != nil ? "checkmark.circle.fill" : "location"
                    )
                    .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundStyle(capturedLocation != nil ? Color.green : Color.accentColor)

                if locationManager.lastKnownLocation == nil {
                    Text(lang.s.locationUnavailable)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

private struct ProfileRow: View {
    let profile: LocationProfile
    @EnvironmentObject var lang: LanguageManager

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name).font(.callout.weight(.medium))
                Text("\(lang.s.preferredNetwork)\(profile.preferredSSID)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if profile.latitude != nil {
                Image(systemName: "location.fill")
                    .foregroundStyle(Color.accentColor)
                    .font(.caption)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - About

private struct AboutTab: View {
    @EnvironmentObject var lang: LanguageManager
    @EnvironmentObject var updaterWrapper: UpdaterWrapper

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(.blue)

            Text("WifiManager")
                .font(.title2.weight(.semibold))
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")")
                .font(.callout)
                .foregroundStyle(.secondary)

            Text(lang.s.appDescription)
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)

            Button(lang.s.checkForUpdates) {
                updaterWrapper.updater.checkForUpdates()
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
