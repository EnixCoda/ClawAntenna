import Foundation
import SwiftData
import os

/// Monitors available RAM and memory pressure.
@Observable
final class MemoryCollector: DataCollector {
    let id = "memory"
    let name = "Memory"
    let icon = "memorychip"
    let description = "Available RAM / memory pressure"

    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "MemoryCollector")
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
        timer = Timer.scheduledTimer(withTimeInterval: 10 * 60, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.recordMemory() }
        }

        recordMemory()
        isRunning = true
        logger.info("Started memory monitoring (every 10 min)")
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        logger.info("Stopped memory monitoring")
    }

    private func recordMemory() {
        let available = Int64(os_proc_available_memory())
        let total = Int64(ProcessInfo.processInfo.physicalMemory)

        let context = ModelContext(modelContainer)
        let record = MemoryRecord(availableBytes: available, totalBytes: total)
        context.insert(record)
        do {
            try context.save()
        } catch {
            lastError = error.localizedDescription
            logger.error("Failed to save memory record: \(error.localizedDescription)")
        }
    }
}
