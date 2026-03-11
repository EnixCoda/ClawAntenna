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
    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "LocationCollector")

    var isAvailable: Bool { true }

    var isRunning: Bool { locationManager.isMonitoring }

    var lastError: String? { locationManager.lastError }

    var permissionStatus: CollectorPermissionStatus {
        switch locationManager.authorizationStatus {
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        case .authorizedWhenInUse: .limited
        case .authorizedAlways: .authorized
        @unknown default: .notDetermined
        }
    }

    /// The underlying location manager — exposed for backward compatibility with views
    /// that need direct access to current location data.
    var manager: LocationManager { locationManager }

    /// Whether the user wants this collector enabled (pending permission).
    private var pendingStart = false

    init(locationManager: LocationManager) {
        self.locationManager = locationManager
    }

    func requestPermission() {
        locationManager.requestPermission()
    }

    func start() {
        pendingStart = true
        if permissionStatus == .notDetermined {
            requestPermission()
            return
        }
        guard permissionStatus.isGranted else {
            logger.warning("Cannot start without location permission")
            pendingStart = false
            return
        }
        locationManager.startMonitoring()
    }

    func stop() {
        pendingStart = false
        locationManager.stopMonitoring()
    }

    /// Called by the app when authorization status changes to resume a pending start.
    func handleAuthorizationChange() {
        guard pendingStart else { return }

        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse:
            // Start monitoring with current permission, then escalate to Always
            locationManager.startMonitoring()
            locationManager.requestPermission()
        case .authorizedAlways:
            locationManager.startMonitoring()
        default:
            break
        }
    }
}
