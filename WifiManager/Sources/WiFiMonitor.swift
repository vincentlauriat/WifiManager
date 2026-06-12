@preconcurrency import CoreWLAN
import Network
import CoreLocation
import SwiftUI
import UserNotifications

@MainActor
class WiFiMonitor: NSObject, ObservableObject {
    @Published var status: ConnectionStatus = .disconnected
    @Published var isWifiEnabled: Bool = true
    @Published var metrics: NetworkMetrics?
    @Published var availableNetworks: [CWNetwork] = []
    @Published var usageScores: [UsageType: NetworkQuality] = [:]
    @Published var isScanning = false
    @Published var isReconnecting = false
    @Published var lastUpdated: Date?
    @Published var connectionError: String?

    private let wifiClient = CWWiFiClient.shared()
    private let typeDetector = ConnectionTypeDetector()
    private let qualityChecker = NetworkQualityChecker()
    private var pollTimer: Timer?
    private var autoReconnectTimer: Timer?
    private var isRefreshing = false
    private var hasCompletedFirstRefresh = false
    // Needed to unlock CWInterface.ssid() on macOS 14+
    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        UserDefaults.standard.register(defaults: [
            "pollInterval": 30.0,
            "autoReconnectInterval": 20.0,
            "notifyOnDisconnect": true,
            "notifyOnHotspot": true,
            "showHotspotBadge": true,
        ])
        locationManager.delegate = self
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        // Single source of truth for network path: refresh once the path is fresh.
        typeDetector.onPathUpdate = { [weak self] in
            Task { @MainActor [weak self] in
                await self?.qualityChecker.invalidateCache()
                await self?.refresh()
            }
        }
        // Ask for notification permission once, up front, instead of at the first alert.
        Task { _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) }
        setupWiFiEvents()
        Task { await refresh() }
        schedulePoll()
    }

    deinit {
        pollTimer?.invalidate()
        autoReconnectTimer?.invalidate()
    }

    // MARK: - Localization

    /// Builds localized strings from the same source of truth as the UI
    /// (`appLanguage` in UserDefaults), without coupling to LanguageManager.
    private var strings: Strings {
        let raw = UserDefaults.standard.string(forKey: "appLanguage") ?? ""
        return Strings(lang: AppLanguage(rawValue: raw) ?? .french)
    }

    // MARK: - Public

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        let previousStatus = status
        defer {
            isRefreshing = false
            notifyIfNeeded(previousStatus: previousStatus)
        }
        connectionError = nil

        guard let interface = wifiClient.interface() else {
            isWifiEnabled = false
            status = .disconnected
            metrics = nil
            return
        }

        isWifiEnabled = interface.powerOn()

        guard isWifiEnabled, typeDetector.isConnected else {
            status = .disconnected
            metrics = nil
            scheduleAutoReconnectIfNeeded()
            return
        }

        // RSSI 0 = interface active mais non associée à un AP
        let rssi = interface.rssiValue()
        guard rssi != 0 else {
            status = .disconnected
            metrics = nil
            scheduleAutoReconnectIfNeeded()
            return
        }

        // ssid() peut retourner nil sans permission localisation (macOS 14+)
        let ssid = interface.ssid() ?? "WiFi"
        let isExpensive = typeDetector.isExpensive
        let latency = await qualityChecker.measureLatency()

        let m = NetworkMetrics(
            ssid: ssid,
            bssid: interface.bssid(),
            rssi: rssi,
            noise: interface.noiseMeasurement(),
            transmitRate: interface.transmitRate(),
            channel: interface.wlanChannel()?.channelNumber,
            latency: latency,
            isExpensive: isExpensive
        )

        self.metrics = m
        self.lastUpdated = Date()
        self.usageScores = qualityChecker.computeUsageScores(metrics: m)
        self.status = isExpensive ? .hotspot(quality: m.quality) : .wifi(quality: m.quality)
        cancelAutoReconnect()
    }

    func reconnect() async {
        guard let interface = wifiClient.interface() else { return }
        let savedSSID = interface.ssid()

        isReconnecting = true
        await qualityChecker.invalidateCache()

        interface.disassociate()
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        if let ssid = savedSSID {
            await scanAndConnect(ssid: ssid, on: interface)
        }

        isReconnecting = false
        await refresh()
    }

    func togglePower() async {
        guard let interface = wifiClient.interface() else { return }
        let enabling = !interface.powerOn()
        try? interface.setPower(enabling)
        isWifiEnabled = enabling
        if !enabling {
            cancelAutoReconnect()
            status = .disconnected
            metrics = nil
            availableNetworks = []
        } else {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await refresh()
        }
    }

    func scanNetworks() async {
        guard let interface = wifiClient.interface() else { return }
        isScanning = true
        defer { isScanning = false }

        nonisolated(unsafe) let iface = interface
        do {
            let networks: Set<CWNetwork> = try await withCheckedThrowingContinuation { cont in
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let result = try iface.scanForNetworks(withName: nil, includeHidden: false)
                        cont.resume(returning: result)
                    } catch {
                        cont.resume(throwing: error)
                    }
                }
            }
            self.availableNetworks = networks
                .filter { $0.ssid != nil }
                .sorted { $0.rssiValue > $1.rssiValue }
        } catch {
            connectionError = strings.scanFailed
        }
    }

    func connect(to network: CWNetwork, password: String? = nil) async {
        guard let interface = wifiClient.interface() else { return }
        connectionError = nil
        do {
            // password nil → CoreWLAN cherche dans le keychain (réseaux déjà connus)
            try interface.associate(to: network, password: password)
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await qualityChecker.invalidateCache()
            await refresh()
        } catch {
            connectionError = strings.connectFailedCheckPassword
        }
    }

    // MARK: - Private

    private func setupWiFiEvents() {
        wifiClient.delegate = self
        let events: [CWEventType] = [
            .ssidDidChange, .bssidDidChange, .linkDidChange,
            .linkQualityDidChange, .powerDidChange
        ]
        for event in events {
            try? wifiClient.startMonitoringEvent(with: event)
        }
    }

    private func schedulePoll() {
        let interval = UserDefaults.standard.double(forKey: "pollInterval")
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
                self?.schedulePoll()
            }
        }
    }

    private func scheduleAutoReconnectIfNeeded() {
        guard autoReconnectTimer == nil else { return }
        guard isWifiEnabled else { return }
        let interval = UserDefaults.standard.double(forKey: "autoReconnectInterval")
        guard interval > 0 else { return }
        autoReconnectTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isWifiEnabled, case .disconnected = self.status else {
                    self?.autoReconnectTimer = nil
                    return
                }
                self.autoReconnectTimer = nil
                await self.refresh()
            }
        }
    }

    private func cancelAutoReconnect() {
        autoReconnectTimer?.invalidate()
        autoReconnectTimer = nil
    }

    private func scanAndConnect(ssid: String, on interface: CWInterface) async {
        nonisolated(unsafe) let iface = interface
        do {
            let networks: Set<CWNetwork> = try await withCheckedThrowingContinuation { cont in
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let result = try iface.scanForNetworks(withName: ssid, includeHidden: false)
                        cont.resume(returning: result)
                    } catch {
                        cont.resume(throwing: error)
                    }
                }
            }
            if let network = networks.first {
                try? iface.associate(to: network, password: nil)
            }
        } catch {}
    }

    // MARK: - Notifications

    private func notifyIfNeeded(previousStatus: ConnectionStatus) {
        guard hasCompletedFirstRefresh else {
            hasCompletedFirstRefresh = true
            return
        }
        let s = strings
        if case .disconnected = status, previousStatus != .disconnected,
           UserDefaults.standard.bool(forKey: "notifyOnDisconnect") {
            sendNotification(title: s.notifDisconnectTitle, body: s.notifDisconnectBody)
        }
        if case .hotspot = status, !previousStatus.isHotspot,
           UserDefaults.standard.bool(forKey: "notifyOnHotspot") {
            sendNotification(title: s.notifHotspotTitle, body: s.notifHotspotBody)
        }
    }

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        // Authorization is requested once at init; if denied, add() is simply a no-op.
        Task { try? await UNUserNotificationCenter.current().add(request) }
    }
}

// Relaie le SSID dès que la permission localisation est accordée
extension WiFiMonitor: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in await self.refresh() }
    }
}

// Réaction instantanée aux événements WiFi (pas de polling)
extension WiFiMonitor: CWEventDelegate {
    nonisolated func ssidDidChangeForWiFiInterface(withName interfaceName: String) {
        Task { @MainActor in await self.refresh() }
    }

    nonisolated func bssidDidChangeForWiFiInterface(withName interfaceName: String) {
        Task { @MainActor in await self.refresh() }
    }

    nonisolated func linkDidChangeForWiFiInterface(withName interfaceName: String) {
        Task { @MainActor in await self.refresh() }
    }

    nonisolated func linkQualityDidChangeForWiFiInterface(withName interfaceName: String, rssi: Int, transmitRate: Double) {
        Task { @MainActor in await self.refresh() }
    }

    nonisolated func powerStateDidChangeForWiFiInterface(withName interfaceName: String) {
        Task { @MainActor in await self.refresh() }
    }

    nonisolated func clientConnectionInterrupted() {
        Task { @MainActor in await self.refresh() }
    }
}
