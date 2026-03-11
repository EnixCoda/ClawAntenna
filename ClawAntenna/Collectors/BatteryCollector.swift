import Foundation
import UIKit
import SwiftData
import os

/// Collects battery level and charging state.
/// Samples on state change (plugged/unplugged) and periodically.
@Observable
final class BatteryCollector: DataCollector {
    let id = "battery"
    let name = "Battery"
    let icon = "battery.100percent"
    let description = "Battery level and charging state"

    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "BatteryCollector")
    private let modelContainer: ModelContainer
    private var timer: Timer?
    private var stateObserver: NSObjectProtocol?
    private var levelObserver: NSObjectProtocol?

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
        UIDevice.current.isBatteryMonitoringEnabled = true

        stateObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.batteryStateDidChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.recordBatteryState() }
        }

        levelObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.batteryLevelDidChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.recordBatteryState() }
        }

        timer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.recordBatteryState() }
        }

        recordBatteryState()
        isRunning = true
        logger.info("Started battery monitoring")
    }

    func stop() {
        if let stateObserver { NotificationCenter.default.removeObserver(stateObserver) }
        if let levelObserver { NotificationCenter.default.removeObserver(levelObserver) }
        stateObserver = nil
        levelObserver = nil
        timer?.invalidate()
        timer = nil
        UIDevice.current.isBatteryMonitoringEnabled = false
        isRunning = false
        logger.info("Stopped battery monitoring")
    }

    private func recordBatteryState() {
        let level = Double(UIDevice.current.batteryLevel)
        let state: String = switch UIDevice.current.batteryState {
        case .unknown: "unknown"
        case .unplugged: "unplugged"
        case .charging: "charging"
        case .full: "full"
        @unknown default: "unknown"
        }

        let context = ModelContext(modelContainer)
        let record = BatteryRecord(level: level, state: state)
        context.insert(record)
        do {
            try context.save()
        } catch {
            lastError = error.localizedDescription
            logger.error("Failed to save battery record: \(error.localizedDescription)")
        }
    }
}
