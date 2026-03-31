import Foundation
import SwiftData
import os

/// Monitors Low Power Mode on/off transitions.
@Observable
final class LowPowerModeCollector: DataCollector {
    let id = "lowpower"
    let name = "Low Power Mode"
    let icon = "bolt.circle"
    let description = "Low power mode on/off transitions"

    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "LowPowerModeCollector")
    private let modelContainer: ModelContainer
    private var observer: NSObjectProtocol?

    private(set) var isRunning = false
    var lastError: String?

    var isAvailable: Bool { true }
    var permissionStatus: CollectorPermissionStatus { .notRequired }

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func requestPermission() {}
    func refreshPermissionStatus() {}

    func start() {
        observer = NotificationCenter.default.addObserver(
            forName: .NSProcessInfoPowerStateDidChange,
            object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.recordLowPowerMode() }
        }

        recordLowPowerMode()
        isRunning = true
        logger.info("Started low power mode monitoring")
    }

    func stop() {
        if let observer { NotificationCenter.default.removeObserver(observer) }
        observer = nil
        isRunning = false
        logger.info("Stopped low power mode monitoring")
    }

    private func recordLowPowerMode() {
        let context = ModelContext(modelContainer)
        let record = LowPowerRecord(isEnabled: ProcessInfo.processInfo.isLowPowerModeEnabled)
        context.insert(record)
        do {
            try context.save()
        } catch {
            lastError = error.localizedDescription
            logger.error("Failed to save low power mode record: \(error.localizedDescription)")
        }
    }
}
