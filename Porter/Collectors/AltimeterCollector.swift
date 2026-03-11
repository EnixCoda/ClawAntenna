import Foundation
import os

// TODO: import CoreMotion

/// Collects barometric pressure and relative altitude using CMAltimeter.
///
/// Barometric data is useful for detecting elevation changes (stairs, hills)
/// and correlating with weather patterns.
@Observable
final class AltimeterCollector: DataCollector {
    let id = "altimeter"
    let name = "Altimeter"
    let icon = "barometer"
    let description = "Barometric pressure, relative altitude"

    private let logger = Logger(subsystem: "co.enix.Porter", category: "AltimeterCollector")

    // TODO: private var altimeter: CMAltimeter?
    // TODO: private var modelContext: ModelContext

    private(set) var isRunning = false
    var lastError: String?

    var isAvailable: Bool {
        // TODO: CMAltimeter.isRelativeAltitudeAvailable()
        true
    }

    var permissionStatus: CollectorPermissionStatus {
        // Altimeter uses the same motion permission as pedometer/activity.
        // TODO: Check CMAltimeter.authorizationStatus()
        .authorized
    }

    func requestPermission() {
        // TODO: Shared with CoreMotion — same permission as activity/pedometer.
        logger.info("TODO: Request altimeter permission")
    }

    func start() {
        guard permissionStatus.isGranted || permissionStatus == .notDetermined else { return }

        // TODO: altimeter = CMAltimeter()
        // TODO: altimeter?.startRelativeAltitudeUpdates(to: .main) { data, error in
        //     guard let data else { return }
        //     let record = AltimeterRecord(
        //         pressure: data.pressure.doubleValue,  // kPa
        //         relativeAltitude: data.relativeAltitude.doubleValue  // meters
        //     )
        //     self.modelContext.insert(record)
        //     try? self.modelContext.save()
        // }

        isRunning = true
        logger.info("TODO: Started altimeter updates")
    }

    func stop() {
        // TODO: altimeter?.stopRelativeAltitudeUpdates()
        // TODO: altimeter = nil
        isRunning = false
        logger.info("Stopped altimeter updates")
    }
}
