import Foundation
import CoreLocation
import os

/// Wraps the existing LocationManager to conform to the DataCollector protocol.
@Observable
final class LocationCollector: DataCollector {
    let id = "location"
    let name = "Location"
    let icon = "location.fill"
    let description = "GPS coordinates, altitude, speed, accuracy"

    private let locationManager: LocationManager
    private let logger = Logger(subsystem: "co.enix.Porter", category: "LocationCollector")

    var isAvailable: Bool { true }

    var isRunning: Bool { locationManager.isMonitoring }

    var lastError: String? { locationManager.lastError }

    var permissionStatus: CollectorPermissionStatus {
        switch locationManager.authorizationStatus {
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        case .authorizedWhenInUse, .authorizedAlways: .authorized
        @unknown default: .notDetermined
        }
    }

    /// The underlying location manager — exposed for backward compatibility with views
    /// that need direct access to current location data.
    var manager: LocationManager { locationManager }

    init(locationManager: LocationManager) {
        self.locationManager = locationManager
    }

    func requestPermission() {
        locationManager.requestPermission()
    }

    func start() {
        guard permissionStatus.isGranted else {
            logger.warning("Cannot start without location permission")
            return
        }
        locationManager.startMonitoring()
    }

    func stop() {
        locationManager.stopMonitoring()
    }
}
