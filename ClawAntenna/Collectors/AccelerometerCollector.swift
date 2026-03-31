import Foundation
import CoreMotion
import SwiftData
import os

/// Captures raw accelerometer data — motion intensity and shake detection.
/// Samples every 30 seconds to conserve battery.
@Observable
final class AccelerometerCollector: DataCollector {
    let id = "accelerometer"
    let name = "Accelerometer"
    let icon = "move.3d"
    let description = "Raw motion intensity, shake detection"

    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "AccelerometerCollector")
    private let modelContainer: ModelContainer
    private let motionManager = CMMotionManager()
    private var timer: Timer?
    private var pendingStart = false

    private(set) var isRunning = false
    var lastError: String?

    var isAvailable: Bool { motionManager.isAccelerometerAvailable }

    private(set) var permissionStatus: CollectorPermissionStatus = .notDetermined

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        refreshPermissionStatus()
    }

    func refreshPermissionStatus() {
        // CoreMotion shares permission with Activity/Pedometer
        permissionStatus = switch CMMotionActivityManager.authorizationStatus() {
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        case .authorized: .authorized
        @unknown default: .notDetermined
        }
    }

    func requestPermission() {
        // Trigger permission via a motion activity query
        let manager = CMMotionActivityManager()
        let now = Date()
        manager.queryActivityStarting(from: now.addingTimeInterval(-60), to: now, to: .main) { [weak self] _, _ in
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
        guard permissionStatus.isGranted else {
            logger.warning("Cannot start without motion permission")
            pendingStart = false
            return
        }
        guard isAvailable else {
            lastError = "Accelerometer not available"
            return
        }
        pendingStart = false

        // Sample every 30 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.sampleAccelerometer() }
        }

        isRunning = true
        logger.info("Started accelerometer monitoring (30s intervals)")
    }

    func stop() {
        pendingStart = false
        timer?.invalidate()
        timer = nil
        isRunning = false
        logger.info("Stopped accelerometer monitoring")
    }

    private func sampleAccelerometer() {
        motionManager.startAccelerometerUpdates()
        // Read after a brief delay to get a fresh sample
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self, let data = self.motionManager.accelerometerData else {
                self?.motionManager.stopAccelerometerUpdates()
                return
            }
            self.motionManager.stopAccelerometerUpdates()

            let context = ModelContext(self.modelContainer)
            let record = AccelerometerRecord(
                x: data.acceleration.x,
                y: data.acceleration.y,
                z: data.acceleration.z
            )
            context.insert(record)
            do {
                try context.save()
            } catch {
                self.lastError = error.localizedDescription
                self.logger.error("Failed to save accelerometer record: \(error.localizedDescription)")
            }
        }
    }
}
