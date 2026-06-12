import XCTest
@testable import WifiManager

final class NetworkQualityTests: XCTestCase {

    func testStrongSignalLowLatencyIsExcellent() {
        XCTAssertEqual(NetworkQuality.from(rssi: -40, latency: 10), .excellent)
    }

    func testWeakSignalNoLatencyIsPoor() {
        // No latency → latencyScore falls back to signalScore (0 here).
        XCTAssertEqual(NetworkQuality.from(rssi: -80, latency: nil), .poor)
    }

    func testMediumSignalNoLatencyIsGood() {
        XCTAssertEqual(NetworkQuality.from(rssi: -60, latency: nil), .good)
    }

    func testStrongSignalHighLatencyAveragesDown() {
        // signalScore 3 + latencyScore 0 → avg 1 → fair
        XCTAssertEqual(NetworkQuality.from(rssi: -40, latency: 200), .fair)
    }

    func testComparableOrdering() {
        XCTAssertLessThan(NetworkQuality.poor, NetworkQuality.fair)
        XCTAssertLessThan(NetworkQuality.fair, NetworkQuality.good)
        XCTAssertLessThan(NetworkQuality.good, NetworkQuality.excellent)
    }
}
