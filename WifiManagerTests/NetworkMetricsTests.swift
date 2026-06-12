import XCTest
@testable import WifiManager

final class NetworkMetricsTests: XCTestCase {

    private func metrics(rssi: Int, noise: Int, latency: Double? = nil) -> NetworkMetrics {
        NetworkMetrics(
            ssid: "Test", bssid: "00:11:22:33:44:55",
            rssi: rssi, noise: noise, transmitRate: 300,
            channel: 36, latency: latency, isExpensive: false
        )
    }

    func testSNRIsSignalMinusNoise() {
        XCTAssertEqual(metrics(rssi: -50, noise: -90).snr, 40)
    }

    func testRSSIBarValueClampsRange() {
        XCTAssertEqual(metrics(rssi: -20, noise: -90).rssiBarValue, 1.0, accuracy: 0.001) // clamped to -30
        XCTAssertEqual(metrics(rssi: -120, noise: -90).rssiBarValue, 0.0, accuracy: 0.001) // clamped to -100
    }

    func testQualityDelegatesToNetworkQuality() {
        let m = metrics(rssi: -40, noise: -90, latency: 10)
        XCTAssertEqual(m.quality, NetworkQuality.from(rssi: -40, latency: 10))
    }

    func testDownloadDefaultsToNil() {
        XCTAssertNil(metrics(rssi: -50, noise: -90).download)
    }
}
