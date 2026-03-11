import Foundation
import CoreMotion
import SwiftData
import os

/// Collects pedometer data: steps, distance, floors, cadence.
@Observable
final class PedometerCollector: DataCollector {
    let id = "pedometer"
    let name = "Pedometer"
    let icon = "shoeprints.fill"
    let description = "Steps, distance, floors climbed, cadence"

    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "PedometerCollector")
    private let modelContainer: ModelContainer
    private var pedometer: CMPedometer?

    private(set) var isRunning = false
    var lastError: String?

    var isAvailable: Bool {
        CMPedometer.isStepCountingAvailable()
    }

    var permissionStatus: CollectorPermissionStatus {
        switch CMPedometer.authorizationStatus() {
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
        let p = CMPedometer()
        p.queryPedometerData(from: Date().addingTimeInterval(-1), to: Date()) { _, _ in }
    }

    func start() {
        guard isAvailable else {
            lastError = "Step counting not available"
            return
        }

        let p = CMPedometer()
        p.startUpdates(from: Date()) { [weak self] data, error in
            guard let self else { return }
            if let error {
                Task { @MainActor in self.lastError = error.localizedDescription }
                return
            }
            guard let data else { return }
            Task { @MainActor in self.handlePedometerData(data) }
        }
        pedometer = p
        isRunning = true
        logger.info("Started pedometer updates")
    }

    func stop() {
        pedometer?.stopUpdates()
        pedometer = nil
        isRunning = false
        logger.info("Stopped pedometer updates")
    }

    private func handlePedometerData(_ data: CMPedometerData) {
        let context = ModelContext(modelContainer)
        let record = PedometerRecord(
            steps: data.numberOfSteps.intValue,
            distance: data.distance?.doubleValue,
            floorsAscended: data.floorsAscended?.intValue,
            floorsDescended: data.floorsDescended?.intValue,
            cadence: data.currentCadence?.doubleValue,
            periodStart: data.startDate,
            periodEnd: data.endDate
        )
        context.insert(record)
        do {
            try context.save()
        } catch {
            lastError = error.localizedDescription
            logger.error("Failed to save pedometer record: \(error.localizedDescription)")
        }
    }
}
