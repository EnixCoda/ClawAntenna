import Foundation
import CoreLocation
import os

@Observable
final class LocationManager: NSObject {
    private let manager = CLLocationManager()
    private let logger = Logger(subsystem: "co.enix.Porter", category: "Location")

    var currentLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus
    var isMonitoring = false
    var lastError: String?

    /// Called when a new location is received. Set by the app to wire up persistence.
    var onLocationUpdate: ((CLLocation) -> Void)?

    override init() {
        self.authorizationStatus = CLLocationManager().authorizationStatus
        super.init()
        manager.delegate = self
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
    }

    // MARK: - Permissions

    func requestPermission() {
        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
        default:
            break
        }
    }

    var hasAlwaysPermission: Bool {
        authorizationStatus == .authorizedAlways
    }

    var hasAnyPermission: Bool {
        authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse
    }

    var permissionDescription: String {
        switch authorizationStatus {
        case .notDetermined: return "Not requested"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedWhenInUse: return "When In Use"
        case .authorizedAlways: return "Always"
        @unknown default: return "Unknown"
        }
    }

    // MARK: - Monitoring

    func startMonitoring() {
        guard hasAnyPermission else {
            logger.warning("Cannot start monitoring without location permission")
            return
        }

        manager.startMonitoringSignificantLocationChanges()
        isMonitoring = true
        logger.info("Started significant location change monitoring")
    }

    func stopMonitoring() {
        manager.stopMonitoringSignificantLocationChanges()
        isMonitoring = false
        logger.info("Stopped location monitoring")
    }

    /// Request a single location update for immediate feedback.
    func requestCurrentLocation() {
        guard hasAnyPermission else { return }
        manager.requestLocation()
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        logger.info("Location update: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        currentLocation = location
        lastError = nil
        onLocationUpdate?(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        logger.error("Location error: \(error.localizedDescription)")
        lastError = error.localizedDescription
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        logger.info("Authorization changed to: \(self.permissionDescription)")
    }
}
