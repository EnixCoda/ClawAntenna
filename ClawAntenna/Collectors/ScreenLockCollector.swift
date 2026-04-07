import Foundation
import SwiftData
import os

/// Monitors screen lock/unlock events via Darwin notifications.
@Observable
final class ScreenLockCollector: DataCollector {
    let id = "screenlock"
    let name = "Screen Lock"
    let icon = "lock.fill"
    let description = "Lock / unlock events"

    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "ScreenLockCollector")
    private let modelContainer: ModelContainer
    private var lockToken: Int32 = 0
    private var unlockToken: Int32 = 0

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
        let lockName = "com.apple.springboard.lockstate" as CFString
        let completeUnlockName = "com.apple.springboard.hasBlankedScreen" as CFString

        let center = CFNotificationCenterGetDarwinNotifyCenter()

        // Lock state changes (0 = unlocked, 1 = locked)
        CFNotificationCenterAddObserver(
            center, Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, _, _, _ in
                guard let observer else { return }
                let this = Unmanaged<ScreenLockCollector>.fromOpaque(observer).takeUnretainedValue()
                Task { @MainActor in this.recordEvent(isLocked: true) }
            },
            lockName, nil, .deliverImmediately
        )

        CFNotificationCenterAddObserver(
            center, Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, _, _, _ in
                guard let observer else { return }
                let this = Unmanaged<ScreenLockCollector>.fromOpaque(observer).takeUnretainedValue()
                Task { @MainActor in this.recordEvent(isLocked: false) }
            },
            completeUnlockName, nil, .deliverImmediately
        )

        isRunning = true
        logger.info("Started screen lock monitoring")
    }

    func stop() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterRemoveEveryObserver(center, Unmanaged.passUnretained(self).toOpaque())
        isRunning = false
        logger.info("Stopped screen lock monitoring")
    }

    private func recordEvent(isLocked: Bool) {
        let context = ModelContext(modelContainer)
        let record = ScreenLockRecord(isLocked: isLocked)
        context.insert(record)
        do {
            try context.save()
        } catch {
            lastError = error.localizedDescription
            logger.error("Failed to save screen lock record: \(error.localizedDescription)")
        }
    }
}
