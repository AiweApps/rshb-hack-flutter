import CoreLocation
import Combine
import Foundation

/// Handles one explicit location request from the assistant. Manual address entry stays available
/// when permission or geocoding fails.
final class AssistantLocationRequester: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var error: String?

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var onResolve: ((Double, Double, String) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func request(onResolve: @escaping (Double, Double, String) -> Void) {
        self.onResolve = onResolve
        error = nil
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            error = String(localized: "assistant_location_denied")
        @unknown default:
            error = String(localized: "assistant_location_failed")
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        } else if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            error = String(localized: "assistant_location_denied")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self else { return }
            let place = placemarks?.first
            let address = [place?.name, place?.locality]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
            guard !address.isEmpty else {
                self.error = String(localized: "assistant_location_failed")
                return
            }
            self.onResolve?(location.coordinate.latitude, location.coordinate.longitude, address)
            self.onResolve = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = String(localized: "assistant_location_failed")
    }
}
