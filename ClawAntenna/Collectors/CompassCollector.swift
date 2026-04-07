import Foundation
import CoreLocation
import SwiftData
import os

/// Tracks compass heading direction.
/// Records on significant heading change (>15°) to conserve battery.
@Observable
final class CompassCollector: DataCollector {
    let id = "compass"
    let name = "Compass"
    let icon = "safari"
    let description = "Heading direction, magnetic / true north"

    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "CompassCollector")
    private let modelContainer: ModelContainer
    private let locationManager: LocationManager
    private var lastRecordedHeading: Double?

    private(set) var isRunning = false
    var lastError: String?

    var isAvailable: Bool { CLLocationManager.headingAvailable() }

    private(set) var permissionStatus: CollectorPermissionStatus = .notDetermined
    private var pendingStart = false

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
        guard isAvailable else {
            lastError = "Compass not available on this device"
            logger.warning("Heading not available")
            return
        }
        locationManager.clManager.headingFilter = 15.0
        locationManager.clManager.startUpdatingHeading()
        locationManager.onHeading = { [weak self] heading in
            guard let self else { return }
            Task { @MainActor in self.recordHeading(heading) }
        }
        isRunning = true
        pendingStart = false
        logger.info("Started compass monitoring (headingFilter = 15°)")
    }

    func stop() {
        pendingStart = false
        locationManager.clManager.stopUpdatingHeading()
        locationManager.onHeading = nil
        isRunning = false
        logger.info("Stopped compass monitoring")
    }

    private func recordHeading(_ heading: CLHeading) {
        guard heading.headingAccuracy >= 0 else { return }

        let context = ModelContext(modelContainer)
        let record = CompassRecord(
            magneticHeading: heading.magneticHeading,
            trueHeading: heading.trueHeading >= 0 ? heading.trueHeading : nil,
            headingAccuracy: heading.headingAccuracy
        )
        context.insert(record)
        do {
            try context.save()
        } catch {
            lastError = error.localizedDescription
            logger.error("Failed to save compass record: \(error.localizedDescription)")
        }
    }
}
