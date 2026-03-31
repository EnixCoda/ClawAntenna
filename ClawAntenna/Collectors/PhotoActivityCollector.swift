import Foundation
import Photos
import SwiftData
import os

/// Monitors photo library size — photo and video count.
/// Samples hourly since it changes slowly.
@Observable
final class PhotoActivityCollector: DataCollector {
    let id = "photoactivity"
    let name = "Photo Activity"
    let icon = "photo.on.rectangle"
    let description = "Photo count, last capture timestamp"

    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "PhotoActivityCollector")
    private let modelContainer: ModelContainer
    private var timer: Timer?
    private var pendingStart = false

    private(set) var isRunning = false
    var lastError: String?

    var isAvailable: Bool { true }

    private(set) var permissionStatus: CollectorPermissionStatus = .notDetermined

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        refreshPermissionStatus()
    }

    func refreshPermissionStatus() {
        permissionStatus = switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        case .authorized: .authorized
        case .limited: .limited
        @unknown default: .notDetermined
        }
    }

    func requestPermission() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] _ in
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
            logger.warning("Cannot start without Photos permission")
            pendingStart = false
            return
        }
        pendingStart = false

        timer = Timer.scheduledTimer(withTimeInterval: 60 * 60, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.recordPhotoActivity() }
        }

        recordPhotoActivity()
        isRunning = true
        logger.info("Started photo activity monitoring (hourly)")
    }

    func stop() {
        pendingStart = false
        timer?.invalidate()
        timer = nil
        isRunning = false
        logger.info("Stopped photo activity monitoring")
    }

    private func recordPhotoActivity() {
        let photoCount = PHAsset.fetchAssets(with: .image, options: nil).count
        let videoCount = PHAsset.fetchAssets(with: .video, options: nil).count

        let context = ModelContext(modelContainer)
        let record = PhotoActivityRecord(photoCount: photoCount, videoCount: videoCount)
        context.insert(record)
        do {
            try context.save()
        } catch {
            lastError = error.localizedDescription
            logger.error("Failed to save photo activity record: \(error.localizedDescription)")
        }
    }
}
