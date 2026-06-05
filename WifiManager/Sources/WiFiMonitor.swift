import CoreWLAN
import Network
import SwiftUI

@MainActor
class WiFiMonitor: ObservableObject {
    @Published var status: ConnectionStatus = .disconnected
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

    init() {
        setupPathMonitor()
        Task { await refresh() }
        startPolling()
    }

    deinit {
        pathMonitor?.cancel()
        pollTimer?.invalidate()
    }

    // MARK: - Public

    func refresh() async {
        connectionError = nil
        guard let interface = wifiClient.interface(),
              interface.powerOn(),
              let ssid = interface.ssid() else {
            status = .disconnected
            metrics = nil
            return
        }

        let isExpensive = typeDetector.isExpensive
        let latency = await qualityChecker.measureLatency()

        let m = NetworkMetrics(
            ssid: ssid,
            bssid: interface.bssid(),
            rssi: interface.rssiValue(),
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

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
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
