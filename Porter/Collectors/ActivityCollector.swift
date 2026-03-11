import Foundation
import os

// TODO: import CoreMotion

/// Detects the user's current activity type using CMMotionActivityManager.
///
/// Activity types: stationary, walking, running, cycling, automotive, unknown.
/// CoreMotion activity detection runs on the motion coprocessor and is very battery-efficient.
@Observable
final class ActivityCollector: DataCollector {
    let id = "activity"
    let name = "Activity"
    let icon = "figure.walk"
    let description = "Stationary, walking, running, cycling, driving"

    private let logger = Logger(subsystem: "co.enix.Porter", category: "ActivityCollector")

    // TODO: private var activityManager: CMMotionActivityManager?
    // TODO: private var modelContext: ModelContext

    private(set) var isRunning = false
    var lastError: String?

    var isAvailable: Bool {
        // TODO: CMMotionActivityManager.isActivityAvailable()
        true
    }

    var permissionStatus: CollectorPermissionStatus {
        // TODO: Check CMMotionActivityManager.authorizationStatus()
        .authorized
    }

    func requestPermission() {
        // TODO: Trigger a one-time query to prompt the motion permission dialog.
        // CMMotionActivityManager doesn't have an explicit requestPermission(),
        // so starting a query triggers the system prompt.
        logger.info("TODO: Request motion permission")
    }

    func start() {
        guard permissionStatus.isGranted || permissionStatus == .notDetermined else {
            logger.warning("Cannot start without motion permission")
            return
        }

        // TODO: activityManager = CMMotionActivityManager()
        // TODO: activityManager?.startActivityUpdates(to: .main) { activity in
        //     guard let activity else { return }
        //     let record = ActivityRecord(
        //         activityType: self.classifyActivity(activity),
        //         confidence: self.classifyConfidence(activity.confidence),
        //         startedAt: activity.startDate
        //     )
        //     self.modelContext.insert(record)
        //     try? self.modelContext.save()
        // }

        isRunning = true
        logger.info("TODO: Started activity monitoring")
    }

    func stop() {
        // TODO: activityManager?.stopActivityUpdates()
        // TODO: activityManager = nil
        isRunning = false
        logger.info("Stopped activity monitoring")
    }
}
