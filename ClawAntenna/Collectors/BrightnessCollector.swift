import Foundation
import UIKit
import SwiftData
import os

/// Monitors screen brightness changes.
/// Event-driven — records when the user changes brightness.
@Observable
final class BrightnessCollector: DataCollector {
    let id = "brightness"
    let name = "Brightness"
    let icon = "sun.max.fill"
    let description = "Screen brightness level (0–100%)"

    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "BrightnessCollector")
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
            forName: UIScreen.brightnessDidChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.recordBrightness() }
        }
        recordBrightness()
        isRunning = true
        logger.info("Started brightness monitoring")
    }

    func stop() {
        if let observer { NotificationCenter.default.removeObserver(observer) }
        observer = nil
        isRunning = false
        logger.info("Stopped brightness monitoring")
    }

    private func recordBrightness() {
        let level = Double(UIScreen.main.brightness)

        let context = ModelContext(modelContainer)
        let record = BrightnessRecord(level: level)
        context.insert(record)
        do {
            try context.save()
        } catch {
            lastError = error.localizedDescription
            logger.error("Failed to save brightness record: \(error.localizedDescription)")
        }
    }
}
