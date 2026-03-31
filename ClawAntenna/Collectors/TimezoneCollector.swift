import Foundation
import SwiftData
import os

/// Monitors timezone changes — useful for travel detection.
@Observable
final class TimezoneCollector: DataCollector {
    let id = "timezone"
    let name = "Timezone"
    let icon = "globe"
    let description = "Timezone changes (travel detection)"

    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "TimezoneCollector")
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
            forName: .NSSystemTimeZoneDidChange,
            object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.recordTimezone() }
        }

        recordTimezone()
        isRunning = true
        logger.info("Started timezone monitoring")
    }

    func stop() {
        if let observer { NotificationCenter.default.removeObserver(observer) }
        observer = nil
        isRunning = false
        logger.info("Stopped timezone monitoring")
    }

    private func recordTimezone() {
        let tz = TimeZone.current
        let context = ModelContext(modelContainer)
        let record = TimezoneRecord(
            identifier: tz.identifier,
            abbreviation: tz.abbreviation(),
            secondsFromGMT: tz.secondsFromGMT()
        )
        context.insert(record)
        do {
            try context.save()
        } catch {
            lastError = error.localizedDescription
            logger.error("Failed to save timezone record: \(error.localizedDescription)")
        }
    }
}
