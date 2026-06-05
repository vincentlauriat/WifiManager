import Foundation

actor NetworkQualityChecker {
    private let testURL = URL(string: "https://www.apple.com/library/test/success.html")!
    private var cachedLatency: Double?
    private var lastTestDate: Date?
    private let cacheDuration: TimeInterval = 30

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

    func invalidateCache() {
        cachedLatency = nil
        lastTestDate = nil
    }

    func computeUsageScores(metrics: NetworkMetrics) async -> [UsageType: NetworkQuality] {
        let latency = metrics.latency
        var scores: [UsageType: NetworkQuality] = [:]
        for usage in UsageType.allCases {
            scores[usage] = usage.quality(latency: latency, download: nil)
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
}
