import Foundation
import CoreMotion
import SwiftData
import os

/// Collects barometric pressure and relative altitude using CMAltimeter.
@Observable
final class AltimeterCollector: DataCollector {
    let id = "altimeter"
    let name = "Altimeter"
    let icon = "barometer"
    let description = "Barometric pressure, relative altitude"

    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "AltimeterCollector")
    private let modelContainer: ModelContainer
    private var altimeter: CMAltimeter?
    private var pendingStart = false

    private(set) var isRunning = false
    private(set) var permissionStatus: CollectorPermissionStatus = .notDetermined
    var lastError: String?

    var isAvailable: Bool {
        CMAltimeter.isRelativeAltitudeAvailable()
    }

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        refreshPermissionStatus()
    }

    func refreshPermissionStatus() {
        permissionStatus = switch CMAltimeter.authorizationStatus() {
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        case .authorized: .authorized
        @unknown default: .notDetermined
        }
    }

    func requestPermission() {
        let a = CMAltimeter()
        a.startRelativeAltitudeUpdates(to: .main) { [weak self] _, _ in
            guard let self else { return }
            self.refreshPermissionStatus()
            if self.pendingStart { self.start() }
        }
        // Stop immediately — we only needed the first callback to trigger the permission prompt
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            a.stopRelativeAltitudeUpdates()
        }
    }

    func start() {
        if permissionStatus == .notDetermined {
            pendingStart = true
            requestPermission()
            return
        }
        guard isAvailable else {
            lastError = "Altimeter not available"
            return
        }
        guard permissionStatus.isGranted else {
            logger.warning("Cannot start without motion permission")
            pendingStart = false
            return
        }

        pendingStart = false
        let a = CMAltimeter()
        a.startRelativeAltitudeUpdates(to: .main) { [weak self] data, error in
            guard let self else { return }
            if let error {
                self.lastError = error.localizedDescription
                return
            }
            guard let data else { return }
            self.handleAltimeterData(data)
        }
        altimeter = a
        isRunning = true
        logger.info("Started altimeter updates")
    }

    func stop() {
        pendingStart = false
        altimeter?.stopRelativeAltitudeUpdates()
        altimeter = nil
        isRunning = false
        logger.info("Stopped altimeter updates")
    }

    private func handleAltimeterData(_ data: CMAltitudeData) {
        let context = ModelContext(modelContainer)
        let record = AltimeterRecord(
            pressure: data.pressure.doubleValue,
            relativeAltitude: data.relativeAltitude.doubleValue
        )
        context.insert(record)
        do {
            try context.save()
        } catch {
            lastError = error.localizedDescription
            logger.error("Failed to save altimeter record: \(error.localizedDescription)")
        }
    }
}
