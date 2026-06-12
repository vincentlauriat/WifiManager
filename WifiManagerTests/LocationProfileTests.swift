import XCTest
import CoreLocation
@testable import WifiManager

final class LocationProfileTests: XCTestCase {

    private let paris = CLLocation(latitude: 48.8566, longitude: 2.3522)

    func testMatchesWithinRadius() {
        let profile = LocationProfile(
            name: "Home", preferredSSID: "Home-WiFi",
            latitude: 48.8566, longitude: 2.3522, radiusMeters: 200
        )
        XCTAssertTrue(profile.matches(location: paris))
    }

    func testDoesNotMatchOutsideRadius() {
        // ~1.1 km north of the profile centre, radius 200 m.
        let profile = LocationProfile(
            name: "Home", preferredSSID: "Home-WiFi",
            latitude: 48.8666, longitude: 2.3522, radiusMeters: 200
        )
        XCTAssertFalse(profile.matches(location: paris))
    }

    func testNoCoordinateNeverMatches() {
        let profile = LocationProfile(name: "Anywhere", preferredSSID: "Cafe")
        XCTAssertNil(profile.coordinate)
        XCTAssertFalse(profile.matches(location: paris))
    }

    func testCoordinateBuiltFromStoredFields() {
        let profile = LocationProfile(
            name: "Office", preferredSSID: "Corp",
            latitude: 10, longitude: 20
        )
        XCTAssertEqual(profile.coordinate?.latitude, 10)
        XCTAssertEqual(profile.coordinate?.longitude, 20)
    }

    func testCodableRoundTrip() throws {
        let profile = LocationProfile(
            name: "Home", preferredSSID: "Home-WiFi",
            latitude: 48.85, longitude: 2.35
        )
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(LocationProfile.self, from: data)
        XCTAssertEqual(decoded.id, profile.id)
        XCTAssertEqual(decoded.preferredSSID, "Home-WiFi")
    }
}
