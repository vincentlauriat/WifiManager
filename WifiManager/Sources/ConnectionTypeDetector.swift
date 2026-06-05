import Network

final class ConnectionTypeDetector {
    private let monitor = NWPathMonitor()
    private(set) var currentPath: NWPath?

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.currentPath = path
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
