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

    private(set) var isRunning = false
    var lastError: String?

    var isAvailable: Bool {
        CMAltimeter.isRelativeAltitudeAvailable()
    }

    var permissionStatus: CollectorPermissionStatus {
        switch CMAltimeter.authorizationStatus() {
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        case .authorized: .authorized
        @unknown default: .notDetermined
        }
    }

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func requestPermission() {
        let a = CMAltimeter()
        a.startRelativeAltitudeUpdates(to: .main) { _, _ in }
        a.stopRelativeAltitudeUpdates()
    }

    func start() {
        guard isAvailable else {
            lastError = "Altimeter not available"
            return
        }

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
