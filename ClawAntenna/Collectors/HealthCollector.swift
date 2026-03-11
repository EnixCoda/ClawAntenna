import Foundation
import HealthKit
import SwiftData
import os

/// Collects health metrics via HealthKit with anchored queries for incremental updates.
@Observable
final class HealthCollector: DataCollector {
    let id = "health"
    let name = "Health"
    let icon = "heart.fill"
    let description = "Heart rate, energy, sleep, workouts"

    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "HealthCollector")
    private let modelContainer: ModelContainer
    private var healthStore: HKHealthStore?
    private var queries: [HKQuery] = []

    private(set) var isRunning = false
    var lastError: String?

    private static let readTypes: Set<HKSampleType> = [
        HKQuantityType(.heartRate),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.stepCount),
        HKCategoryType(.sleepAnalysis),
    ]

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    var permissionStatus: CollectorPermissionStatus {
        guard isAvailable, let store = healthStore else { return .notDetermined }
        let status = store.authorizationStatus(for: HKQuantityType(.heartRate))
        return switch status {
        case .notDetermined: .notDetermined
        case .sharingDenied: .denied
        case .sharingAuthorized: .authorized
        @unknown default: .notDetermined
        }
    }

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        if HKHealthStore.isHealthDataAvailable() {
            self.healthStore = HKHealthStore()
        }
    }

    func requestPermission() {
        guard let healthStore else { return }
        healthStore.requestAuthorization(toShare: [], read: Self.readTypes) { [weak self] _, error in
            if let error {
                guard let self else { return }
                Task { @MainActor in
                    self.lastError = error.localizedDescription
                    self.logger.error("HealthKit authorization failed: \(error.localizedDescription)")
                }
            }
        }
    }

    func start() {
        guard healthStore != nil else {
            lastError = "HealthKit not available"
            return
        }

        setupQuantityObserver(for: HKQuantityType(.heartRate), metricType: "heart_rate", unit: HKUnit.count().unitDivided(by: .minute()), unitName: "bpm")
        setupQuantityObserver(for: HKQuantityType(.activeEnergyBurned), metricType: "active_energy", unit: .kilocalorie(), unitName: "kcal")
        setupQuantityObserver(for: HKQuantityType(.stepCount), metricType: "step_count", unit: .count(), unitName: "steps")
        setupCategoryObserver(for: HKCategoryType(.sleepAnalysis), metricType: "sleep")

        isRunning = true
        logger.info("Started HealthKit observation")
    }

    func stop() {
        guard let healthStore else { return }
        for query in queries { healthStore.stop(query) }
        queries.removeAll()
        isRunning = false
        logger.info("Stopped HealthKit observation")
    }

    private func setupQuantityObserver(for type: HKQuantityType, metricType: String, unit: HKUnit, unitName: String) {
        guard let healthStore else { return }

        let query = HKAnchoredObjectQuery(
            type: type,
            predicate: HKQuery.predicateForSamples(withStart: Date(), end: nil),
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, error in
            guard let self else { return }
            Task { @MainActor in
                self.handleQuantitySamples(samples, metricType: metricType, unit: unit, unitName: unitName, error: error)
            }
        }

        query.updateHandler = { [weak self] _, samples, _, _, error in
            guard let self else { return }
            Task { @MainActor in
                self.handleQuantitySamples(samples, metricType: metricType, unit: unit, unitName: unitName, error: error)
            }
        }

        healthStore.execute(query)
        queries.append(query)
    }

    private func setupCategoryObserver(for type: HKCategoryType, metricType: String) {
        guard let healthStore else { return }

        let query = HKAnchoredObjectQuery(
            type: type,
            predicate: HKQuery.predicateForSamples(withStart: Date(), end: nil),
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, error in
            guard let self else { return }
            Task { @MainActor in
                self.handleCategorySamples(samples, metricType: metricType, error: error)
            }
        }

        query.updateHandler = { [weak self] _, samples, _, _, error in
            guard let self else { return }
            Task { @MainActor in
                self.handleCategorySamples(samples, metricType: metricType, error: error)
            }
        }

        healthStore.execute(query)
        queries.append(query)
    }

    private func handleQuantitySamples(_ samples: [HKSample]?, metricType: String, unit: HKUnit, unitName: String, error: Error?) {
        guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else { return }

        Task { @MainActor in
            let context = ModelContext(self.modelContainer)
            for sample in samples {
                let record = HealthRecord(
                    metricType: metricType,
                    value: sample.quantity.doubleValue(for: unit),
                    unit: unitName,
                    startedAt: sample.startDate,
                    endedAt: sample.endDate
                )
                context.insert(record)
            }
            do { try context.save() } catch {
                self.lastError = error.localizedDescription
            }
        }
    }

    private func handleCategorySamples(_ samples: [HKSample]?, metricType: String, error: Error?) {
        guard let samples = samples as? [HKCategorySample], !samples.isEmpty else { return }

        Task { @MainActor in
            let context = ModelContext(self.modelContainer)
            for sample in samples {
                let record = HealthRecord(
                    metricType: metricType,
                    value: Double(sample.value),
                    startedAt: sample.startDate,
                    endedAt: sample.endDate
                )
                context.insert(record)
            }
            do { try context.save() } catch {
                self.lastError = error.localizedDescription
            }
        }
    }
}
