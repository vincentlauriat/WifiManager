import SwiftUI
import Sparkle

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
        .frame(width: 420, height: 320)
    }
}

// MARK: - General

private struct GeneralTab: View {
    @AppStorage("pollInterval") private var pollInterval: Double = 30
    @AppStorage("showHotspotBadge") private var showHotspotBadge = true
    @AppStorage("notifyOnDisconnect") private var notifyOnDisconnect = true
    @AppStorage("notifyOnHotspot") private var notifyOnHotspot = true
    @AppStorage("launchAtLogin") private var launchAtLogin = false
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
            }
            Section(lang.s.notifications) {
                Toggle(lang.s.notifyDisconnect, isOn: $notifyOnDisconnect)
                Toggle(lang.s.notifyHotspot, isOn: $notifyOnHotspot)
            }
            Section(lang.s.startup) {
                Toggle(lang.s.launchAtLogin, isOn: $launchAtLogin)
                    .disabled(true)
                Text(lang.s.launchAtLoginNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
    @State private var showAdd = false
    @State private var newName = ""
    @State private var newSSID = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if locationManager.authorizationStatus == .denied ||
               locationManager.authorizationStatus == .restricted {
                locationWarning
            }

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
                    newName = ""; newSSID = ""
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
        HStack(spacing: 8) {
            TextField(lang.s.locationName, text: $newName)
                .textFieldStyle(.roundedBorder)
            TextField(lang.s.networkSSID, text: $newSSID)
                .textFieldStyle(.roundedBorder)
            Button(lang.s.add) {
                guard !newName.isEmpty, !newSSID.isEmpty else { return }
                locationManager.add(profile: LocationProfile(name: newName, preferredSSID: newSSID))
                newName = ""; newSSID = ""; showAdd = false
            }
            .buttonStyle(.borderedProminent)
            .disabled(newName.isEmpty || newSSID.isEmpty)
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
            Text("Version 1.0.0")
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
