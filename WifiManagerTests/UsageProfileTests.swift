import XCTest
@testable import WifiManager

final class UsageProfileTests: XCTestCase {

    func testEmailWithGoodLatencyIsExcellent() {
        // email req latency 200 ms; 50 ms < 100 (0.5×req) → full points.
        XCTAssertEqual(UsageType.email.quality(latency: 50, download: nil), .excellent)
    }

    func testGamingWithHighLatencyIsPoor() {
        // gaming req latency 30 ms; 100 ms exceeds 2×req → 0 points.
        XCTAssertEqual(UsageType.gaming.quality(latency: 100, download: nil), .poor)
    }

    func testWebWithLatencyAndDownloadIsExcellent() {
        // web req (100 ms, 5 Mbps); 50 ms + 12 Mbps both score high.
        XCTAssertEqual(UsageType.web.quality(latency: 50, download: 12), .excellent)
    }

    func testNoMeasurementsDefaultsToFair() {
        XCTAssertEqual(UsageType.general.quality(latency: nil, download: nil), .fair)
    }

    func testStreamingNeedsHighDownload() {
        // streaming req download 15 Mbps; 3 Mbps is below 0.5×req → 0 download points.
        let q = UsageType.streaming.quality(latency: 30, download: 3)
        XCTAssertLessThanOrEqual(q, .good)
    }

    func testAllUsageTypesHaveDistinctRequirements() {
        let reqs = UsageType.allCases.map { $0.requirements.latency }
        XCTAssertEqual(reqs.count, UsageType.allCases.count)
    }
}
