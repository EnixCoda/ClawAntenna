import Foundation
import UIKit
import os

/// Collects battery level and charging state.
///
/// Samples on state change (plugged/unplugged) and periodically.
/// No special permissions required — uses UIDevice APIs.
@Observable
final class BatteryCollector: DataCollector {
    let id = "battery"
    let name = "Battery"
    let icon = "battery.100percent"
    let description = "Battery level and charging state"

    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "BatteryCollector")

    // TODO: private var timer: Timer?
    // TODO: private var modelContext: ModelContext

    private(set) var isRunning = false
    var lastError: String?

    var isAvailable: Bool { true }

    /// No permission needed for battery monitoring.
    var permissionStatus: CollectorPermissionStatus { .notRequired }

    func requestPermission() {
        // No-op — battery monitoring requires no permission.
    }

    func start() {
        // TODO: UIDevice.current.isBatteryMonitoringEnabled = true
        //
        // TODO: Observe battery state changes via NotificationCenter:
        //   NotificationCenter.default.addObserver(
        //       forName: UIDevice.batteryStateDidChangeNotification, ...)
        //   NotificationCenter.default.addObserver(
        //       forName: UIDevice.batteryLevelDidChangeNotification, ...)
        //
        // TODO: Also sample periodically (e.g. every 15 minutes) via Timer.

        isRunning = true
        logger.info("TODO: Started battery monitoring")
    }

    func stop() {
        // TODO: UIDevice.current.isBatteryMonitoringEnabled = false
        // TODO: Remove notification observers
        // TODO: timer?.invalidate(); timer = nil
        isRunning = false
        logger.info("Stopped battery monitoring")
    }

    // TODO: private func recordBatteryState() {
    //     let level = Double(UIDevice.current.batteryLevel)  // 0.0–1.0
    //     let state = switch UIDevice.current.batteryState {
    //         case .unknown: "unknown"
    //         case .unplugged: "unplugged"
    //         case .charging: "charging"
    //         case .full: "full"
    //         @unknown default: "unknown"
    //     }
    //     let record = BatteryRecord(level: level, state: state)
    //     modelContext.insert(record)
    //     try? modelContext.save()
    // }
}
