import Foundation
import UIKit
import SwiftData
import os

/// Monitors proximity sensor — detects when phone is near face or in pocket.
@Observable
final class ProximityCollector: DataCollector {
    let id = "proximity"
    let name = "Proximity"
    let icon = "hand.raised"
    let description = "Phone near face / in pocket"

    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "ProximityCollector")
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
        UIDevice.current.isProximityMonitoringEnabled = true

        observer = NotificationCenter.default.addObserver(
            forName: UIDevice.proximityStateDidChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.recordProximity() }
        }

        isRunning = true
        logger.info("Started proximity monitoring")
    }

    func stop() {
        if let observer { NotificationCenter.default.removeObserver(observer) }
        observer = nil
        UIDevice.current.isProximityMonitoringEnabled = false
        isRunning = false
        logger.info("Stopped proximity monitoring")
    }

    private func recordProximity() {
        let context = ModelContext(modelContainer)
        let record = ProximityRecord(isNear: UIDevice.current.proximityState)
        context.insert(record)
        do {
            try context.save()
        } catch {
            lastError = error.localizedDescription
            logger.error("Failed to save proximity record: \(error.localizedDescription)")
        }
    }
}
