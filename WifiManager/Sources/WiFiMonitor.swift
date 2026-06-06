@preconcurrency import CoreWLAN
import Network
import CoreLocation
import SwiftUI

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
    private var pathMonitor: NWPathMonitor?
    private var pollTimer: Timer?
    private var autoReconnectTimer: Timer?
    private var isRefreshing = false
    // Needed to unlock CWInterface.ssid() on macOS 14+
    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        setupPathMonitor()
        setupWiFiEvents()
        Task { await refresh() }
        schedulePoll()
    }

    deinit {
        pathMonitor?.cancel()
        pollTimer?.invalidate()
        autoReconnectTimer?.invalidate()
    }

    // MARK: - Public

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        connectionError = nil

        guard let interface = wifiClient.interface() else {
            isWifiEnabled = false
            status = .disconnected
            metrics = nil
            scheduleAutoReconnectIfNeeded()
            return
        }

        isWifiEnabled = interface.powerOn()

        guard isWifiEnabled, typeDetector.isConnected else {
            status = .disconnected
            metrics = nil
            scheduleAutoReconnectIfNeeded()
            return
        }

        let rssi = interface.rssiValue()
        // RSSI 0 = interface active mais non associée à un AP
        guard rssi != 0 else {
            status = .disconnected
            metrics = nil
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
        self.usageScores = await qualityChecker.computeUsageScores(metrics: m)
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

        do {
            let networks: Set<CWNetwork> = try await withCheckedThrowingContinuation { cont in
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let result = try interface.scanForNetworks(withName: nil, includeHidden: false)
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
            connectionError = "Impossible de scanner les réseaux."
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
            connectionError = "Connexion échouée. Vérifiez le mot de passe."
        }
    }

    // MARK: - Private

    private func setupPathMonitor() {
        let monitor = NWPathMonitor()
        pathMonitor = monitor
        monitor.pathUpdateHandler = { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.qualityChecker.invalidateCache()
                await self?.refresh()
            }
        }
        monitor.start(queue: .global(qos: .utility))
    }

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
        let raw = UserDefaults.standard.double(forKey: "pollInterval")
        let interval = raw > 0 ? raw : 30
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
        let effectiveInterval = interval > 0 ? interval : 20
        guard UserDefaults.standard.object(forKey: "autoReconnectInterval") == nil || interval > 0 else { return }
        autoReconnectTimer = Timer.scheduledTimer(withTimeInterval: effectiveInterval, repeats: false) { [weak self] _ in
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
        do {
            let networks: Set<CWNetwork> = try await withCheckedThrowingContinuation { cont in
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let result = try interface.scanForNetworks(withName: ssid, includeHidden: false)
                        cont.resume(returning: result)
                    } catch {
                        cont.resume(throwing: error)
                    }
                }
            }
            if let network = networks.first {
                try? interface.associate(to: network, password: nil)
            }
        } catch {}
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
