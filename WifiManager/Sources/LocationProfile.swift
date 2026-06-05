import Foundation
import CoreLocation

struct LocationProfile: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var preferredSSID: String
    var latitude: Double?
    var longitude: Double?
    var radiusMeters: Double = 200

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    func matches(location: CLLocation) -> Bool {
        guard let coord = coordinate else { return false }
        let profileLocation = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        return location.distance(from: profileLocation) <= radiusMeters
    }
}
