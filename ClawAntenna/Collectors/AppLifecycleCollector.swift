import Foundation
import UIKit
import SwiftData
import os

/// Tracks foreground/background transitions — measures phone pickup frequency.
@Observable
final class AppLifecycleCollector: DataCollector {
    let id = "lifecycle"
    let name = "App Lifecycle"
    let icon = "iphone.and.arrow.forward"
    let description = "Foreground/background transitions (phone pickups)"

    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "AppLifecycleCollector")
    private let modelContainer: ModelContainer
    private var foregroundObserver: NSObjectProtocol?
    private var backgroundObserver: NSObjectProtocol?

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
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.recordEvent("foreground") }
        }

        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.recordEvent("background") }
        }

        isRunning = true
        logger.info("Started app lifecycle monitoring")
    }

    func stop() {
        if let foregroundObserver { NotificationCenter.default.removeObserver(foregroundObserver) }
        if let backgroundObserver { NotificationCenter.default.removeObserver(backgroundObserver) }
        foregroundObserver = nil
        backgroundObserver = nil
        isRunning = false
        logger.info("Stopped app lifecycle monitoring")
    }

    private func recordEvent(_ event: String) {
        let context = ModelContext(modelContainer)
        let record = AppLifecycleRecord(event: event)
        context.insert(record)
        do {
            try context.save()
        } catch {
            lastError = error.localizedDescription
            logger.error("Failed to save lifecycle record: \(error.localizedDescription)")
        }
    }
}
