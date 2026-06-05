import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralTab()
                .tabItem { Label("Général", systemImage: "gearshape") }
            LocationTab()
                .tabItem { Label("Lieux", systemImage: "location") }
            AboutTab()
                .tabItem { Label("À propos", systemImage: "info.circle") }
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

    var body: some View {
        Form {
            Section("Surveillance") {
                Picker("Vérification toutes les", selection: $pollInterval) {
                    Text("10 s").tag(10.0)
                    Text("30 s").tag(30.0)
                    Text("1 min").tag(60.0)
                    Text("5 min").tag(300.0)
                }
                Toggle("Afficher le badge Partage de connexion", isOn: $showHotspotBadge)
            }
            Section("Notifications") {
                Toggle("Alerter si la connexion est perdue", isOn: $notifyOnDisconnect)
                Toggle("Alerter si l'on passe sur un partage de connexion", isOn: $notifyOnHotspot)
            }
            Section("Démarrage") {
                Toggle("Lancer WifiManager au démarrage", isOn: $launchAtLogin)
                    .disabled(true)
                Text("Fonctionnalité disponible dans une prochaine version.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Locations

private struct LocationTab: View {
    @EnvironmentObject var locationManager: LocationProfileManager
    @State private var showAdd = false
    @State private var editingProfile: LocationProfile?
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
                    Label(showAdd ? "Annuler" : "Ajouter un lieu", systemImage: showAdd ? "xmark" : "plus")
                }
                .buttonStyle(.bordered)

                Spacer()

                Text("\(locationManager.profiles.count) lieu(x) enregistré(s)")
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
            Text("Localisation refusée — la détection automatique est désactivée.")
                .font(.caption)
            Spacer()
            Button("Ouvrir Réglages") {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices")!)
            }
            .controlSize(.small)
        }
        .padding(10)
        .background(.orange.opacity(0.1))
    }

    private var addForm: some View {
        HStack(spacing: 8) {
            TextField("Nom du lieu", text: $newName)
                .textFieldStyle(.roundedBorder)
            TextField("SSID WiFi", text: $newSSID)
                .textFieldStyle(.roundedBorder)
            Button("Ajouter") {
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

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name).font(.callout.weight(.medium))
                Text("Réseau : \(profile.preferredSSID)")
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

            Text("Surveille la qualité de votre connexion WiFi et distingue les réseaux réels des partages de connexion.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)

            Spacer()
        }
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
