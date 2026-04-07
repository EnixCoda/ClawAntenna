import Foundation
import CoreLocation
import os

@Observable
final class LocationManager {
    private var manager: CLLocationManager?
    private var delegate: LocationDelegate?
    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "Location")

    var currentLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isMonitoring = false
    var lastError: String?

    var onLocationUpdate: ((CLLocation) -> Void)?
    var onAuthorizationChange: (() -> Void)?
    var onVisit: ((CLVisit) -> Void)?
    var onHeading: ((CLHeading) -> Void)?
    var onRegionEnter: ((CLRegion) -> Void)?
    var onRegionExit: ((CLRegion) -> Void)?

    /// Direct access to the underlying CLLocationManager for visit/heading APIs.
    var clManager: CLLocationManager { manager! }

    /// Must be called once from the main thread after the view appears.
    func setup() {
        guard manager == nil else { return }
        let del = LocationDelegate()
        let mgr = CLLocationManager()
        mgr.delegate = del

        del.onUpdate = { [weak self] location in
            self?.handleLocationUpdate(location)
        }
        del.onError = { [weak self] error in
            self?.lastError = error.localizedDescription
            self?.logger.error("Location error: \(error.localizedDescription)")
        }
        del.onAuthChange = { [weak self] status in
            self?.authorizationStatus = status
            self?.logger.info("Authorization changed to: \(status.rawValue)")
            self?.onAuthorizationChange?()
        }
        del.onVisit = { [weak self] visit in
            self?.onVisit?(visit)
        }
        del.onHeading = { [weak self] heading in
            self?.onHeading?(heading)
        }
        del.onRegionEnter = { [weak self] region in
            self?.onRegionEnter?(region)
        }
        del.onRegionExit = { [weak self] region in
            self?.onRegionExit?(region)
        }

        self.delegate = del
        self.manager = mgr
        self.authorizationStatus = mgr.authorizationStatus
    }

    /// Enable background updates — call only after permissions are granted.
    private func enableBackgroundUpdates() {
        manager?.allowsBackgroundLocationUpdates = true
        manager?.pausesLocationUpdatesAutomatically = false
    }

    private func handleLocationUpdate(_ location: CLLocation) {
        logger.info("Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        currentLocation = location
        lastError = nil
        onLocationUpdate?(location)
    }

    // MARK: - Permissions

    func requestPermission() {
        guard let manager else { return }
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
        case .notDetermined: "Not requested"
        case .restricted: "Restricted"
        case .denied: "Denied"
        case .authorizedWhenInUse: "When In Use"
        case .authorizedAlways: "Always"
        @unknown default: "Unknown"
        }
    }

    // MARK: - Monitoring

    func startMonitoring() {
        guard hasAnyPermission else {
            logger.warning("Cannot start monitoring without location permission")
            return
        }
        enableBackgroundUpdates()
        manager?.startMonitoringSignificantLocationChanges()
        isMonitoring = true
        logger.info("Started significant location change monitoring")
    }

    func stopMonitoring() {
        manager?.stopMonitoringSignificantLocationChanges()
        isMonitoring = false
        logger.info("Stopped location monitoring")
    }

    func requestCurrentLocation() {
        guard hasAnyPermission else { return }
        manager?.requestLocation()
    }
}

private class LocationDelegate: NSObject, CLLocationManagerDelegate {
    var onUpdate: ((CLLocation) -> Void)?
    var onError: ((Error) -> Void)?
    var onAuthChange: ((CLAuthorizationStatus) -> Void)?
    var onVisit: ((CLVisit) -> Void)?
    var onHeading: ((CLHeading) -> Void)?
    var onRegionEnter: ((CLRegion) -> Void)?
    var onRegionExit: ((CLRegion) -> Void)?

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        onUpdate?(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        onError?(error)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        onAuthChange?(manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        onVisit?(visit)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        onHeading?(newHeading)
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        onRegionEnter?(region)
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        onRegionExit?(region)
    }
}
