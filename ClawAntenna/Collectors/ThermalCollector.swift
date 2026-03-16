import Foundation
import SwiftData
import os

/// Monitors device thermal state changes.
/// Event-driven — only records when the thermal state transitions.
@Observable
final class ThermalCollector: DataCollector {
    let id = "thermal"
    let name = "Thermal"
    let icon = "thermometer.medium"
    let description = "Device thermal state (nominal → critical)"

    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "ThermalCollector")
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
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.recordThermalState() }
        }
        recordThermalState()
        isRunning = true
        logger.info("Started thermal monitoring")
    }

    func stop() {
        if let observer { NotificationCenter.default.removeObserver(observer) }
        observer = nil
        isRunning = false
        logger.info("Stopped thermal monitoring")
    }

    private func recordThermalState() {
        let state: String = switch ProcessInfo.processInfo.thermalState {
        case .nominal: "nominal"
        case .fair: "fair"
        case .serious: "serious"
        case .critical: "critical"
        @unknown default: "unknown"
        }

        let context = ModelContext(modelContainer)
        let record = ThermalRecord(state: state)
        context.insert(record)
        do {
            try context.save()
        } catch {
            lastError = error.localizedDescription
            logger.error("Failed to save thermal record: \(error.localizedDescription)")
        }
    }
}
