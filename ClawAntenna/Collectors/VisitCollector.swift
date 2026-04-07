import Foundation
import CoreLocation
import SwiftData
import os

/// Detects automatic place arrival/departure using CLVisit monitoring.
/// Reuses existing location permission — no additional prompt needed.
@Observable
final class VisitCollector: DataCollector {
    let id = "visits"
    let name = "Visits"
    let icon = "mappin.and.ellipse"
    let description = "Automatic place arrival / departure detection"

    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "VisitCollector")
    private let modelContainer: ModelContainer
    private let locationManager: LocationManager

    private(set) var isRunning = false
    var lastError: String?

    var isAvailable: Bool { locationManager.authorizationStatus != .restricted }

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
        locationManager.clManager.startMonitoringVisits()
        locationManager.onVisit = { [weak self] visit in
            guard let self else { return }
            Task { @MainActor in self.recordVisit(visit) }
        }
        isRunning = true
        pendingStart = false
        logger.info("Started visit monitoring")
    }

    func stop() {
        pendingStart = false
        locationManager.clManager.stopMonitoringVisits()
        locationManager.onVisit = nil
        isRunning = false
        logger.info("Stopped visit monitoring")
    }

    private func recordVisit(_ visit: CLVisit) {
        let arrivalAt = visit.arrivalDate == .distantPast ? nil : visit.arrivalDate
        let departureAt = visit.departureDate == .distantFuture ? nil : visit.departureDate

        let context = ModelContext(modelContainer)
        let record = VisitRecord(
            latitude: visit.coordinate.latitude,
            longitude: visit.coordinate.longitude,
            horizontalAccuracy: visit.horizontalAccuracy,
            arrivalAt: arrivalAt,
            departureAt: departureAt
        )
        context.insert(record)
        do {
            try context.save()
        } catch {
            lastError = error.localizedDescription
            logger.error("Failed to save visit record: \(error.localizedDescription)")
        }
    }
}
