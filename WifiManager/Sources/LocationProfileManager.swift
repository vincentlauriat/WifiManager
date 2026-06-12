import Foundation
import CoreLocation

@MainActor
class LocationProfileManager: NSObject, ObservableObject {
    @Published var profiles: [LocationProfile] = []
    @Published var currentProfile: LocationProfile?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    /// Most recent fix, used by the Preferences form to stamp a profile's coordinates.
    @Published var lastKnownLocation: CLLocation?

    /// Fired when the device *enters* a profile's radius (transition only, not on every fix).
    /// Wired by the app to trigger an auto network switch.
    var onProfileEnter: ((LocationProfile) -> Void)?

    private let locationManager = CLLocationManager()
    private let storageKey = "WifiManager.locationProfiles"

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 100
        authorizationStatus = locationManager.authorizationStatus
        load()
        startMonitoring()
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startMonitoring() {
        // macOS only ever reports `.authorizedAlways` for a granted app
        // (there is no when-in-use distinction on macOS).
        guard authorizationStatus == .authorizedAlways else { return }
        locationManager.startUpdatingLocation()
    }

    func stopMonitoring() {
        locationManager.stopUpdatingLocation()
    }

    func add(profile: LocationProfile) {
        profiles.append(profile)
        save()
    }

    func remove(at offsets: IndexSet) {
        profiles.remove(atOffsets: offsets)
        save()
    }

    func update(profile: LocationProfile) {
        guard let idx = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        profiles[idx] = profile
        save()
    }

    private func matchProfile(to location: CLLocation) {
        let matched = profiles.first { $0.matches(location: location) }
        // Fire the enter callback only on a genuine transition into a new profile.
        if let matched, matched.id != currentProfile?.id {
            onProfileEnter?(matched)
        }
        currentProfile = matched
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([LocationProfile].self, from: data) else { return }
        profiles = decoded
    }
}

extension LocationProfileManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.lastKnownLocation = location
            self.matchProfile(to: location)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Read the status here (nonisolated) so we don't send `manager` across actors.
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            if status == .authorizedAlways {
                self.startMonitoring()
            }
        }
    }
}
