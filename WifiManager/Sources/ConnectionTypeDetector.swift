import Network

@MainActor
final class ConnectionTypeDetector {
    private let monitor = NWPathMonitor()
    private(set) var currentPath: NWPath?
    /// Fired on the main actor *after* `currentPath` is updated, so observers
    /// always read a fresh path (no cross-monitor race).
    var onPathUpdate: (() -> Void)?

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.currentPath = path
                self?.onPathUpdate?()
            }
        }
        monitor.start(queue: .global(qos: .utility))
    }

    deinit {
        monitor.cancel()
    }

    var isConnected: Bool {
        currentPath?.status == .satisfied
    }

    // true when using a personal hotspot or cellular tethering
    var isExpensive: Bool {
        currentPath?.isExpensive ?? false
    }

    var isConstrained: Bool {
        currentPath?.isConstrained ?? false
    }
}
