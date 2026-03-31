import Foundation
import CoreLocation
import SwiftData
import os

/// Monitors geofence region enter/exit events.
/// Uses the existing location permission.
@Observable
final class GeofenceCollector: DataCollector {
    let id = "geofence"
    let name = "Geofence"
    let icon = "mappin.circle"
    let description = "Region enter/exit events"

    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "GeofenceCollector")
    private let modelContainer: ModelContainer
    private let locationManager: LocationManager
    private var pendingStart = false

    private(set) var isRunning = false
    var lastError: String?

    var isAvailable: Bool { CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) }

    private(set) var permissionStatus: CollectorPermissionStatus = .notDetermined

    init(locationManager: LocationManager, modelContainer: ModelContainer) {
        self.locationManager = locationManager
        self.modelContainer = modelContainer
        refreshPermissionStatus()
    }

    func refreshPermissionStatus() {
        permissionStatus = switch locationManager.authorizationStatus {
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        case .authorizedWhenInUse: .limited
        case .authorizedAlways: .authorized
        @unknown default: .notDetermined
        }
    }

    func requestPermission() {
        locationManager.requestPermission()
    }

    func start() {
        if permissionStatus == .notDetermined {
            pendingStart = true
            requestPermission()
            return
        }
        guard permissionStatus.isGranted else {
            logger.warning("Cannot start without location permission")
            pendingStart = false
            return
        }
        pendingStart = false

        locationManager.onRegionEnter = { [weak self] region in
            guard let self else { return }
            Task { @MainActor in self.recordEvent(region: region, event: "enter") }
        }
        locationManager.onRegionExit = { [weak self] region in
            guard let self else { return }
            Task { @MainActor in self.recordEvent(region: region, event: "exit") }
        }

        isRunning = true
        logger.info("Started geofence monitoring")
    }

    func stop() {
        pendingStart = false
        locationManager.onRegionEnter = nil
        locationManager.onRegionExit = nil
        // Stop monitoring all regions
        for region in locationManager.clManager.monitoredRegions {
            locationManager.clManager.stopMonitoring(for: region)
        }
        isRunning = false
        logger.info("Stopped geofence monitoring")
    }

    private func recordEvent(region: CLRegion, event: String) {
        let context = ModelContext(modelContainer)
        let record = GeofenceRecord(regionIdentifier: region.identifier, event: event)
        context.insert(record)
        do {
            try context.save()
        } catch {
            lastError = error.localizedDescription
            logger.error("Failed to save geofence record: \(error.localizedDescription)")
        }
    }
}
