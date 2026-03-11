import Foundation
import os

// TODO: import CoreMotion

/// Collects pedometer data: steps, distance, floors, cadence.
///
/// Uses CMPedometer for real-time step counting. The motion coprocessor handles
/// counting even when the app is suspended, so this is very battery-efficient.
@Observable
final class PedometerCollector: DataCollector {
    let id = "pedometer"
    let name = "Pedometer"
    let icon = "shoeprints.fill"
    let description = "Steps, distance, floors climbed, cadence"

    private let logger = Logger(subsystem: "co.enix.Porter", category: "PedometerCollector")

    // TODO: private var pedometer: CMPedometer?
    // TODO: private var modelContext: ModelContext

    private(set) var isRunning = false
    var lastError: String?

    var isAvailable: Bool {
        // TODO: CMPedometer.isStepCountingAvailable()
        true
    }

    var permissionStatus: CollectorPermissionStatus {
        // TODO: Check CMPedometer.authorizationStatus()
        .authorized
    }

    func requestPermission() {
        // TODO: CMPedometer permission is requested on first query.
        logger.info("TODO: Request pedometer permission")
    }

    func start() {
        guard permissionStatus.isGranted || permissionStatus == .notDetermined else { return }

        // TODO: pedometer = CMPedometer()
        // TODO: pedometer?.startUpdates(from: Date()) { data, error in
        //     guard let data else { return }
        //     let record = PedometerRecord(
        //         steps: data.numberOfSteps.intValue,
        //         distance: data.distance?.doubleValue,
        //         floorsAscended: data.floorsAscended?.intValue,
        //         floorsDescended: data.floorsDescended?.intValue,
        //         cadence: data.currentCadence?.doubleValue,
        //         periodStart: data.startDate,
        //         periodEnd: data.endDate
        //     )
        //     self.modelContext.insert(record)
        //     try? self.modelContext.save()
        // }

        isRunning = true
        logger.info("TODO: Started pedometer updates")
    }

    func stop() {
        // TODO: pedometer?.stopUpdates()
        // TODO: pedometer = nil
        isRunning = false
        logger.info("Stopped pedometer updates")
    }
}
