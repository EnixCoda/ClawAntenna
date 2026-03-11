import Foundation
import os

// TODO: import HealthKit

/// Collects health metrics via HealthKit with background delivery.
///
/// Supported metrics: heart rate, resting heart rate, active energy burned,
/// sleep analysis, and workout sessions. Each metric type can be individually toggled.
///
/// Requires the HealthKit entitlement and explicit user authorization per data type.
@Observable
final class HealthCollector: DataCollector {
    let id = "health"
    let name = "Health"
    let icon = "heart.fill"
    let description = "Heart rate, energy, sleep, workouts"

    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "HealthCollector")

    // TODO: private var healthStore: HKHealthStore?
    // TODO: private var modelContext: ModelContext
    // TODO: private var observerQueries: [HKObserverQuery] = []

    private(set) var isRunning = false
    var lastError: String?

    var isAvailable: Bool {
        // TODO: HKHealthStore.isHealthDataAvailable()
        true
    }

    var permissionStatus: CollectorPermissionStatus {
        // TODO: HealthKit uses per-type authorization. Check the combination
        // of requested types to determine overall status.
        // HKHealthStore().authorizationStatus(for:) per type.
        .authorized
    }

    func requestPermission() {
        // TODO: Define the set of HKObjectType to read:
        //   - HKQuantityType(.heartRate)
        //   - HKQuantityType(.restingHeartRate)
        //   - HKQuantityType(.activeEnergyBurned)
        //   - HKCategoryType(.sleepAnalysis)
        //   - HKWorkoutType.workoutType()
        //
        // TODO: healthStore?.requestAuthorization(toShare: [], read: readTypes) { ... }
        logger.info("TODO: Request HealthKit authorization")
    }

    func start() {
        guard permissionStatus.isGranted || permissionStatus == .notDetermined else { return }

        // TODO: For each metric type, set up an HKObserverQuery with
        //       enableBackgroundDelivery(for:frequency:) so we receive
        //       updates even when the app is in the background.
        //
        // TODO: On each observer callback, run an HKAnchoredObjectQuery
        //       to fetch only new samples since the last anchor, then
        //       create HealthRecord entries and insert into modelContext.
        //
        // Example for heart rate:
        // let heartRateType = HKQuantityType(.heartRate)
        // let query = HKObserverQuery(sampleType: heartRateType, predicate: nil) { _, completionHandler, error in
        //     // Fetch new samples with anchored query
        //     // Create HealthRecord(metricType: "heart_rate", value: bpm, unit: "bpm")
        //     completionHandler()
        // }
        // healthStore?.execute(query)
        // healthStore?.enableBackgroundDelivery(for: heartRateType, frequency: .hourly) { ... }

        isRunning = true
        logger.info("TODO: Started HealthKit observation")
    }

    func stop() {
        // TODO: for query in observerQueries { healthStore?.stop(query) }
        // TODO: observerQueries.removeAll()
        isRunning = false
        logger.info("Stopped HealthKit observation")
    }
}
