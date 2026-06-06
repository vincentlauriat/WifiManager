import Foundation

struct Strings {
    let lang: AppLanguage

    // MARK: - Status

    var disconnected: String {
        lang == .french ? "Déconnecté" : "Disconnected"
    }
    var hotspot: String {
        lang == .french ? "Partage de connexion" : "Hotspot"
    }
    var notConnected: String {
        lang == .french ? "Non connecté" : "Not Connected"
    }
    var noActiveWifi: String {
        lang == .french ? "Aucun réseau WiFi actif" : "No active WiFi network"
    }
    var justNow: String {
        lang == .french ? "à l'instant" : "just now"
    }
    func secsAgo(_ s: Int) -> String {
        lang == .french ? "il y a \(s) s" : "\(s)s ago"
    }
    func minAgo(_ m: Int) -> String {
        lang == .french ? "il y a \(m) min" : "\(m)min ago"
    }
    func channel(_ ch: Int) -> String {
        lang == .french ? "Canal \(ch)" : "Ch. \(ch)"
    }

    // MARK: - Quality

    var poor: String { lang == .french ? "Mauvaise" : "Poor" }
    var fair: String { lang == .french ? "Correcte" : "Fair" }
    var good: String { lang == .french ? "Bonne" : "Good" }
    var excellent: String { lang == .french ? "Excellente" : "Excellent" }

    func qualityLabel(for quality: NetworkQuality) -> String {
        switch quality {
        case .poor: return poor
        case .fair: return fair
        case .good: return good
        case .excellent: return excellent
        }
    }

    func statusLabel(for status: ConnectionStatus) -> String {
        switch status {
        case .disconnected: return disconnected
        case .hotspot(let q): return lang == .french ? "Partage (\(qualityLabel(for: q)))" : "Hotspot (\(qualityLabel(for: q)))"
        case .wifi(let q): return qualityLabel(for: q)
        }
    }

    // MARK: - Usages

    var usageQualityTitle: String {
        lang == .french ? "Qualité par usage" : "Quality per use"
    }

    func usageName(for usage: UsageType) -> String {
        switch usage {
        case .email:     return lang == .french ? "E-mail" : "Email"
        case .web:       return lang == .french ? "Navigation" : "Browsing"
        case .videoCall: return lang == .french ? "Visio" : "Video Call"
        case .gaming:    return lang == .french ? "Gaming" : "Gaming"
        case .streaming: return lang == .french ? "Streaming" : "Streaming"
        case .general:   return lang == .french ? "Général" : "General"
        }
    }

    // MARK: - Actions

    var reconnect: String {
        lang == .french ? "Relancer la connexion" : "Reconnect"
    }
    var reconnecting: String {
        lang == .french ? "Reconnexion en cours…" : "Reconnecting…"
    }
    var availableNetworks: String {
        lang == .french ? "Réseaux disponibles" : "Available Networks"
    }
    var scanning: String {
        lang == .french ? "Recherche des réseaux…" : "Scanning…"
    }
    var noNetworks: String {
        lang == .french ? "Aucun réseau trouvé" : "No networks found"
    }
    var join: String {
        lang == .french ? "Rejoindre" : "Join"
    }
    var cancel: String {
        lang == .french ? "Annuler" : "Cancel"
    }
    var wifiPassword: String {
        lang == .french ? "Mot de passe WiFi" : "WiFi Password"
    }
    var connectionFailed: String {
        lang == .french ? "Connexion échouée" : "Connection failed"
    }
    var refresh: String {
        lang == .french ? "Actualiser" : "Refresh"
    }
    var unknownNetwork: String {
        lang == .french ? "Réseau inconnu" : "Unknown Network"
    }

    // MARK: - Metrics

    var signal: String { lang == .french ? "Signal" : "Signal" }
    var latency: String { lang == .french ? "Latence" : "Latency" }
    var linkSpeed: String { lang == .french ? "Débit lien" : "Link Speed" }
    var snr: String { "SNR" }

    // MARK: - Settings

    var settings: String { lang == .french ? "Préférences" : "Settings" }
    var tabGeneral: String { lang == .french ? "Général" : "General" }
    var tabLocations: String { lang == .french ? "Lieux" : "Locations" }
    var tabAbout: String { lang == .french ? "À propos" : "About" }
    var language: String { lang == .french ? "Langue" : "Language" }
    var checkForUpdates: String { lang == .french ? "Vérifier les mises à jour…" : "Check for Updates…" }
    var quit: String { lang == .french ? "Quitter WifiManager" : "Quit WifiManager" }
    var preferencesHelp: String { lang == .french ? "Préférences WifiManager" : "WifiManager Preferences" }

    // MARK: - Settings sections

    var monitoring: String { lang == .french ? "Surveillance" : "Monitoring" }
    var notifications: String { lang == .french ? "Notifications" : "Notifications" }
    var startup: String { lang == .french ? "Démarrage" : "Startup" }
    var pollIntervalLabel: String {
        lang == .french ? "Vérification toutes les" : "Check every"
    }
    var hotspotBadge: String {
        lang == .french ? "Afficher le badge Partage de connexion" : "Show hotspot badge"
    }
    var notifyDisconnect: String {
        lang == .french ? "Alerter si la connexion est perdue" : "Alert on disconnection"
    }
    var notifyHotspot: String {
        lang == .french ? "Alerter si l'on passe sur un partage de connexion" : "Alert when switching to hotspot"
    }
    var launchAtLogin: String {
        lang == .french ? "Lancer WifiManager au démarrage" : "Launch WifiManager at login"
    }
    // MARK: - Auto-reconnect

    var autoReconnect: String { lang == .french ? "Reconnexion automatique" : "Auto-Reconnect" }
    var reconnectIntervalLabel: String { lang == .french ? "Réessayer toutes les" : "Retry every" }
    var disabled: String { lang == .french ? "Désactivé" : "Disabled" }

    // MARK: - WiFi power

    var wifiOff: String { lang == .french ? "WiFi désactivé" : "WiFi Off" }
    var wifiOffNote: String {
        lang == .french ? "Le WiFi est désactivé sur cet appareil." : "WiFi is disabled on this device."
    }
    var enableWifi: String { lang == .french ? "Activer le WiFi" : "Enable WiFi" }
    var disableWifi: String { lang == .french ? "Désactiver le WiFi" : "Disable WiFi" }

    // MARK: - System icon

    var systemIcon: String { lang == .french ? "Icône système" : "System Icon" }
    var systemIconNote: String {
        lang == .french
            ? "Pour remplacer l'icône WiFi native de macOS, masquez-la dans Réglages Système > Centre de contrôle > WiFi."
            : "To replace the native macOS WiFi icon, hide it in System Settings > Control Center > WiFi."
    }
    var openControlCenter: String {
        lang == .french ? "Ouvrir Centre de contrôle…" : "Open Control Center Settings…"
    }

    // MARK: - Locations tab

    var locationDenied: String {
        lang == .french
            ? "Localisation refusée — la détection automatique est désactivée."
            : "Location denied — automatic detection is disabled."
    }
    var openSystemSettings: String {
        lang == .french ? "Ouvrir Réglages" : "Open Settings"
    }
    var addLocation: String {
        lang == .french ? "Ajouter un lieu" : "Add Location"
    }
    var locationName: String {
        lang == .french ? "Nom du lieu" : "Location name"
    }
    var networkSSID: String { "SSID WiFi" }
    var add: String { lang == .french ? "Ajouter" : "Add" }

    func locationsCountLabel(_ count: Int) -> String {
        lang == .french
            ? "\(count) lieu(x) enregistré(s)"
            : "\(count) location(s) saved"
    }

    var preferredNetwork: String {
        lang == .french ? "Réseau : " : "Network: "
    }

    // MARK: - About

    var appDescription: String {
        lang == .french
            ? "Surveille la qualité de votre connexion WiFi et distingue les réseaux réels des partages de connexion."
            : "Monitors your WiFi connection quality and distinguishes real networks from hotspots."
    }
}
