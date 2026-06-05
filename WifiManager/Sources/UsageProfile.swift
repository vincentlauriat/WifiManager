import SwiftUI

enum UsageType: String, CaseIterable, Identifiable {
    case email
    case web
    case videoCall
    case gaming
    case streaming
    case general

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .email: return "E-mail"
        case .web: return "Navigation"
        case .videoCall: return "Visio"
        case .gaming: return "Gaming"
        case .streaming: return "Streaming"
        case .general: return "Général"
        }
    }

    var icon: String {
        switch self {
        case .email: return "envelope.fill"
        case .web: return "globe"
        case .videoCall: return "video.fill"
        case .gaming: return "gamecontroller.fill"
        case .streaming: return "play.rectangle.fill"
        case .general: return "wifi"
        }
    }

    // (maxLatencyMs, minDownloadMbps)
    var requirements: (latency: Double, download: Double) {
        switch self {
        case .email:     return (200, 1)
        case .web:       return (100, 5)
        case .videoCall: return (50,  3)
        case .gaming:    return (30,  5)
        case .streaming: return (100, 15)
        case .general:   return (100, 5)
        }
    }

    func quality(latency: Double?, download: Double?) -> NetworkQuality {
        let req = requirements
        var points = 0
        var total = 0

        if let l = latency {
            total += 3
            if l < req.latency * 0.5 { points += 3 }
            else if l < req.latency  { points += 2 }
            else if l < req.latency * 2 { points += 1 }
        }

        if let d = download {
            total += 3
            if d >= req.download * 2  { points += 3 }
            else if d >= req.download { points += 2 }
            else if d >= req.download * 0.5 { points += 1 }
        }

        guard total > 0 else {
            // No measurements yet — derive from latency alone if available
            if let l = latency {
                if l < 30  { return .excellent }
                if l < 80  { return .good }
                if l < 150 { return .fair }
                return .poor
            }
            return .fair
        }

        let ratio = Double(points) / Double(total)
        if ratio >= 0.80 { return .excellent }
        if ratio >= 0.60 { return .good }
        if ratio >= 0.30 { return .fair }
        return .poor
    }
}
