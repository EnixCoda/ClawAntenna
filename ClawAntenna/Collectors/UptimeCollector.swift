import Foundation
import SwiftData
import os

/// Records device uptime periodically — useful for detecting reboots.
@Observable
final class UptimeCollector: DataCollector {
    let id = "uptime"
    let name = "Uptime"
    let icon = "clock.arrow.circlepath"
    let description = "Device uptime / last reboot"

    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "UptimeCollector")
    private let modelContainer: ModelContainer
    private var timer: Timer?

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
        timer = Timer.scheduledTimer(withTimeInterval: 30 * 60, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.recordUptime() }
        }

        recordUptime()
        isRunning = true
        logger.info("Started uptime monitoring (every 30 min)")
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        logger.info("Stopped uptime monitoring")
    }

    private func recordUptime() {
        let context = ModelContext(modelContainer)
        let record = UptimeRecord(uptimeSeconds: ProcessInfo.processInfo.systemUptime)
        context.insert(record)
        do {
            try context.save()
        } catch {
            lastError = error.localizedDescription
            logger.error("Failed to save uptime record: \(error.localizedDescription)")
        }
    }
}
