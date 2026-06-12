import SwiftUI

enum ConnectionStatus: Equatable {
    case disconnected
    case hotspot(quality: NetworkQuality)
    case wifi(quality: NetworkQuality)

    var quality: NetworkQuality? {
        switch self {
        case .disconnected: return nil
        case .hotspot(let q), .wifi(let q): return q
        }
    }

    var isHotspot: Bool {
        if case .hotspot = self { return true }
        return false
    }

    var iconColor: Color {
        switch quality {
        case .none, .poor: return .red
        case .fair: return .orange
        case .good, .excellent: return .green
        }
    }

    var statusLabel: String {
        switch self {
        case .disconnected: return "Déconnecté"
        case .hotspot(let q): return "Partage (\(q.label))"
        case .wifi(let q): return q.label
        }
    }
}

enum NetworkQuality: Int, Comparable {
    case poor = 0
    case fair = 1
    case good = 2
    case excellent = 3

    static func < (lhs: NetworkQuality, rhs: NetworkQuality) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .poor: return "Mauvaise"
        case .fair: return "Correcte"
        case .good: return "Bonne"
        case .excellent: return "Excellente"
        }
    }

    var color: Color {
        switch self {
        case .poor: return .red
        case .fair: return .orange
        case .good, .excellent: return .green
        }
    }

    static func from(rssi: Int, latency: Double?) -> NetworkQuality {
        let signalScore: Int
        switch rssi {
        case (-50)...: signalScore = 3
        case (-65)...(-51): signalScore = 2
        case (-75)...(-66): signalScore = 1
        default: signalScore = 0
        }

        let latencyScore: Int
        if let ms = latency {
            switch ms {
            case ..<20: latencyScore = 3
            case 20..<50: latencyScore = 2
            case 50..<150: latencyScore = 1
            default: latencyScore = 0
            }
        } else {
            latencyScore = signalScore
        }

        let avg = (signalScore + latencyScore) / 2
        return NetworkQuality(rawValue: avg) ?? .poor
    }
}

struct NetworkMetrics {
    let ssid: String
    let bssid: String?
    let rssi: Int
    let noise: Int
    let transmitRate: Double
    let channel: Int?
    let latency: Double?
    let isExpensive: Bool
    /// Measured download throughput in Mbps, `nil` when the speed test is disabled,
    /// pending, or skipped (metered link).
    var download: Double? = nil

    var snr: Int { rssi - noise }

    var rssiBarValue: Double {
        let clamped = max(-100, min(-30, rssi))
        return Double(clamped + 100) / 70.0
    }

    var quality: NetworkQuality {
        NetworkQuality.from(rssi: rssi, latency: latency)
    }
}
