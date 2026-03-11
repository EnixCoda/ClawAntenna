import Foundation
import SwiftData
import os

/// Central manager that holds all data collectors and provides a unified interface.
@Observable
final class CollectorManager {
    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "CollectorManager")

    let collectors: [any DataCollector]

    let location: LocationCollector
    let activity: ActivityCollector
    let pedometer: PedometerCollector
    let altimeter: AltimeterCollector
    let battery: BatteryCollector
    let connectivity: ConnectivityCollector
    let health: HealthCollector

    init(locationManager: LocationManager, modelContainer: ModelContainer) {
        let location = LocationCollector(locationManager: locationManager)
        let activity = ActivityCollector(modelContainer: modelContainer)
        let pedometer = PedometerCollector(modelContainer: modelContainer)
        let altimeter = AltimeterCollector(modelContainer: modelContainer)
        let battery = BatteryCollector(modelContainer: modelContainer)
        let connectivity = ConnectivityCollector(modelContainer: modelContainer)
        let health = HealthCollector(modelContainer: modelContainer)

        self.location = location
        self.activity = activity
        self.pedometer = pedometer
        self.altimeter = altimeter
        self.battery = battery
        self.connectivity = connectivity
        self.health = health

        self.collectors = [location, activity, pedometer, altimeter, battery, connectivity, health]
    }

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

    func stopAll() {
        for collector in collectors where collector.isRunning {
            collector.stop()
            logger.info("Stopped collector: \(collector.id)")
        }
    }

    var activeCount: Int {
        collectors.filter(\.isRunning).count
    }

    var availableCount: Int {
        collectors.filter(\.isAvailable).count
    }
}
