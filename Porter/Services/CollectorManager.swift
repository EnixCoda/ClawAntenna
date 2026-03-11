import Foundation
import os

/// Central manager that holds all data collectors and provides a unified interface.
///
/// The CollectorManager is the single source of truth for which collectors exist,
/// their current state, and bulk operations like starting/stopping all collectors.
@Observable
final class CollectorManager {
    private let logger = Logger(subsystem: "co.enix.Porter", category: "CollectorManager")

    let collectors: [any DataCollector]

    /// Convenience accessors for specific collectors.
    let location: LocationCollector
    let activity: ActivityCollector
    let pedometer: PedometerCollector
    let altimeter: AltimeterCollector
    let battery: BatteryCollector
    let connectivity: ConnectivityCollector
    let health: HealthCollector

    init(locationManager: LocationManager) {
        let location = LocationCollector(locationManager: locationManager)
        let activity = ActivityCollector()
        let pedometer = PedometerCollector()
        let altimeter = AltimeterCollector()
        let battery = BatteryCollector()
        let connectivity = ConnectivityCollector()
        let health = HealthCollector()

        self.location = location
        self.activity = activity
        self.pedometer = pedometer
        self.altimeter = altimeter
        self.battery = battery
        self.connectivity = connectivity
        self.health = health

        self.collectors = [location, activity, pedometer, altimeter, battery, connectivity, health]
    }

    /// Start all collectors that are enabled in settings and have permission.
    func startEnabled(settings: AppSettings) {
        for collector in collectors {
            let key = "collector_\(collector.id)_enabled"
            let isEnabled = UserDefaults.standard.bool(forKey: key)
            if isEnabled && collector.permissionStatus.isGranted {
                collector.start()
                logger.info("Started collector: \(collector.id)")
            }
        }
    }

    /// Stop all running collectors.
    func stopAll() {
        for collector in collectors where collector.isRunning {
            collector.stop()
            logger.info("Stopped collector: \(collector.id)")
        }
    }

    /// Number of collectors currently running.
    var activeCount: Int {
        collectors.filter(\.isRunning).count
    }

    /// Number of collectors available on this device.
    var availableCount: Int {
        collectors.filter(\.isAvailable).count
    }
}
