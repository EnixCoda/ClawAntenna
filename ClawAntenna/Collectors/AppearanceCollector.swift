import Foundation
import UIKit
import SwiftData
import os

/// Monitors dark mode / light mode changes.
@Observable
final class AppearanceCollector: DataCollector {
    let id = "appearance"
    let name = "Appearance"
    let icon = "circle.lefthalf.filled"
    let description = "Dark mode / light mode changes"

    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "AppearanceCollector")
    private let modelContainer: ModelContainer
    private var observer: NSObjectProtocol?
    private var lastRecordedStyle: String?

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
        // Check periodically since there's no direct notification for trait changes outside a view
        observer = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.checkAndRecord() }
        }

        checkAndRecord()
        isRunning = true
        logger.info("Started appearance monitoring")
    }

    func stop() {
        if let observer { NotificationCenter.default.removeObserver(observer) }
        observer = nil
        isRunning = false
        lastRecordedStyle = nil
        logger.info("Stopped appearance monitoring")
    }

    private func checkAndRecord() {
        let style: String
        switch UITraitCollection.current.userInterfaceStyle {
        case .dark: style = "dark"
        case .light: style = "light"
        case .unspecified: style = "unspecified"
        @unknown default: style = "unknown"
        }

        guard style != lastRecordedStyle else { return }
        lastRecordedStyle = style

        let context = ModelContext(modelContainer)
        let record = AppearanceRecord(style: style)
        context.insert(record)
        do {
            try context.save()
        } catch {
            lastError = error.localizedDescription
            logger.error("Failed to save appearance record: \(error.localizedDescription)")
        }
    }
}
