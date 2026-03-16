import Foundation
import SwiftData
import os

/// Monitors available and total disk space.
/// Samples every hour since storage changes slowly.
@Observable
final class StorageCollector: DataCollector {
    let id = "storage"
    let name = "Storage"
    let icon = "internaldrive"
    let description = "Available / total disk space"

    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "StorageCollector")
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
        timer = Timer.scheduledTimer(withTimeInterval: 60 * 60, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.recordStorage() }
        }
        recordStorage()
        isRunning = true
        logger.info("Started storage monitoring (hourly)")
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        logger.info("Stopped storage monitoring")
    }

    private func recordStorage() {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let totalSize = attrs[.systemSize] as? Int64,
              let freeSize = attrs[.systemFreeSize] as? Int64 else {
            lastError = "Unable to read storage attributes"
            logger.error("Failed to read storage attributes")
            return
        }

        let context = ModelContext(modelContainer)
        let record = StorageRecord(totalBytes: totalSize, availableBytes: freeSize)
        context.insert(record)
        do {
            try context.save()
        } catch {
            lastError = error.localizedDescription
            logger.error("Failed to save storage record: \(error.localizedDescription)")
        }
    }
}
