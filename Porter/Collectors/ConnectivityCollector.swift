import Foundation
import Network
import os

/// Monitors network connectivity type and quality using NWPathMonitor.
///
/// Logs changes between Wi-Fi, cellular, and disconnected states.
/// No special permissions required.
@Observable
final class ConnectivityCollector: DataCollector {
    let id = "connectivity"
    let name = "Connectivity"
    let icon = "wifi"
    let description = "Wi-Fi, cellular, connection quality"

    private let logger = Logger(subsystem: "co.enix.Porter", category: "ConnectivityCollector")

    // TODO: private var monitor: NWPathMonitor?
    // TODO: private let monitorQueue = DispatchQueue(label: "co.enix.Porter.connectivity")
    // TODO: private var modelContext: ModelContext

    private(set) var isRunning = false
    var lastError: String?

    var isAvailable: Bool { true }

    /// No permission needed for network path monitoring.
    var permissionStatus: CollectorPermissionStatus { .notRequired }

    func requestPermission() {
        // No-op — network monitoring requires no permission.
    }

    func start() {
        // TODO: monitor = NWPathMonitor()
        // TODO: monitor?.pathUpdateHandler = { [weak self] path in
        //     let networkType: String
        //     if path.usesInterfaceType(.wifi) {
        //         networkType = "wifi"
        //     } else if path.usesInterfaceType(.cellular) {
        //         networkType = "cellular"
        //     } else if path.usesInterfaceType(.wiredEthernet) {
        //         networkType = "wired"
        //     } else {
        //         networkType = "none"
        //     }
        //
        //     let record = ConnectivityRecord(
        //         networkType: networkType,
        //         isExpensive: path.isExpensive,
        //         isConstrained: path.isConstrained
        //     )
        //     // Insert on main actor
        //     Task { @MainActor in
        //         self?.modelContext.insert(record)
        //         try? self?.modelContext.save()
        //     }
        // }
        // TODO: monitor?.start(queue: monitorQueue)

        isRunning = true
        logger.info("TODO: Started connectivity monitoring")
    }

    func stop() {
        // TODO: monitor?.cancel()
        // TODO: monitor = nil
        isRunning = false
        logger.info("Stopped connectivity monitoring")
    }
}
