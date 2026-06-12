import Foundation

actor NetworkQualityChecker {
    private let testURL = URL(string: "https://www.apple.com/library/test/success.html")!
    // Cloudflare's sized-download endpoint — returns exactly `bytes` of payload.
    private let downloadTestBytes = 2_000_000
    private var downloadTestURL: URL {
        URL(string: "https://speed.cloudflare.com/__down?bytes=\(downloadTestBytes)")!
    }
    private var cachedLatency: Double?
    private var lastTestDate: Date?
    private let cacheDuration: TimeInterval = 30

    private var cachedDownload: Double?
    private var lastDownloadDate: Date?
    // Download is heavier than latency: cache longer and never run on metered links.
    private let downloadCacheDuration: TimeInterval = 180

    func measureLatency() async -> Double? {
        if let cached = cachedLatency,
           let date = lastTestDate,
           Date().timeIntervalSince(date) < cacheDuration {
            return cached
        }
        let result = await performLatencyTest()
        if let result {
            cachedLatency = result
            lastTestDate = Date()
        }
        return result
    }

    /// Measures download throughput in Mbps. Returns `nil` on a metered link
    /// (to avoid burning hotspot data) or on failure. Cached for `downloadCacheDuration`.
    func measureDownloadSpeed(isExpensive: Bool) async -> Double? {
        guard !isExpensive else { return nil }
        if let cached = cachedDownload,
           let date = lastDownloadDate,
           Date().timeIntervalSince(date) < downloadCacheDuration {
            return cached
        }
        let result = await performDownloadTest()
        if let result {
            cachedDownload = result
            lastDownloadDate = Date()
        }
        return result
    }

    func invalidateCache() {
        cachedLatency = nil
        lastTestDate = nil
        cachedDownload = nil
        lastDownloadDate = nil
    }

    nonisolated func computeUsageScores(metrics: NetworkMetrics) -> [UsageType: NetworkQuality] {
        var scores: [UsageType: NetworkQuality] = [:]
        for usage in UsageType.allCases {
            scores[usage] = usage.quality(latency: metrics.latency, download: metrics.download)
        }
        return scores
    }

    private func performLatencyTest() async -> Double? {
        var request = URLRequest(url: testURL)
        request.timeoutInterval = 5
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpMethod = "HEAD"

        let start = Date()
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            return Date().timeIntervalSince(start) * 1000
        } catch {
            return nil
        }
    }

    private func performDownloadTest() async -> Double? {
        var request = URLRequest(url: downloadTestURL)
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let start = Date()
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let seconds = Date().timeIntervalSince(start)
            guard seconds > 0 else { return nil }
            // bytes → bits → Mbps
            return (Double(data.count) * 8) / seconds / 1_000_000
        } catch {
            return nil
        }
    }
}
