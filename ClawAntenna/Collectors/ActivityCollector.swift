import Foundation
import CoreMotion
import SwiftData
import os

/// Detects the user's current activity type using CMMotionActivityManager.
@Observable
final class ActivityCollector: DataCollector {
    let id = "activity"
    let name = "Activity"
    let icon = "figure.walk"
    let description = "Stationary, walking, running, cycling, driving"

    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "ActivityCollector")
    private let modelContainer: ModelContainer
    private var activityManager: CMMotionActivityManager?
    private var pendingStart = false

    private(set) var isRunning = false
    private(set) var permissionStatus: CollectorPermissionStatus = .notDetermined
    var lastError: String?

    var isAvailable: Bool {
        CMMotionActivityManager.isActivityAvailable()
    }

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        refreshPermissionStatus()
    }

    func refreshPermissionStatus() {
        permissionStatus = switch CMMotionActivityManager.authorizationStatus() {
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        case .authorized: .authorized
        @unknown default: .notDetermined
        }
    }

    func requestPermission() {
        let manager = CMMotionActivityManager()
        manager.queryActivityStarting(from: Date(), to: Date(), to: .main) { [weak self] _, _ in
            guard let self else { return }
            Task { @MainActor in
                self.refreshPermissionStatus()
                if self.pendingStart { self.start() }
            }
        }
    }

    func start() {
        if permissionStatus == .notDetermined {
            pendingStart = true
            requestPermission()
            return
        }
        guard isAvailable else {
            lastError = "Activity detection not available"
            return
        }
        guard permissionStatus.isGranted else {
            logger.warning("Cannot start without motion permission")
            pendingStart = false
            return
        }

        pendingStart = false
        let manager = CMMotionActivityManager()
        manager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let activity, let self else { return }
            self.handleActivity(activity)
        }
        activityManager = manager
        isRunning = true
        logger.info("Started activity monitoring")
    }

    func stop() {
        pendingStart = false
        activityManager?.stopActivityUpdates()
        activityManager = nil
        isRunning = false
        logger.info("Stopped activity monitoring")
    }

    private func handleActivity(_ activity: CMMotionActivity) {
        let type: String
        if activity.automotive { type = "automotive" }
        else if activity.cycling { type = "cycling" }
        else if activity.running { type = "running" }
        else if activity.walking { type = "walking" }
        else if activity.stationary { type = "stationary" }
        else { type = "unknown" }

        let confidence: String = switch activity.confidence {
        case .low: "low"
        case .medium: "medium"
        case .high: "high"
        @unknown default: "unknown"
        }

        let context = ModelContext(modelContainer)
        let record = ActivityRecord(activityType: type, confidence: confidence, startedAt: activity.startDate)
        context.insert(record)
        do {
            try context.save()
        } catch {
            lastError = error.localizedDescription
            logger.error("Failed to save activity record: \(error.localizedDescription)")
        }
    }
}
