import Foundation
import CoreLocation

@MainActor
class LocationProfileManager: NSObject, ObservableObject {
    @Published var profiles: [LocationProfile] = []
    @Published var currentProfile: LocationProfile?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let locationManager = CLLocationManager()
    private let storageKey = "WifiManager.locationProfiles"

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 100
        authorizationStatus = locationManager.authorizationStatus
        load()
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startMonitoring() {
        guard authorizationStatus == .authorized || authorizationStatus == .authorizedAlways else { return }
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
        currentProfile = profiles.first { $0.matches(location: location) }
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
        Task { @MainActor in self.matchProfile(to: location) }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorized || manager.authorizationStatus == .authorizedAlways {
                self.startMonitoring()
            }
        }
    }
}
