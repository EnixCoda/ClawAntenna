import Foundation
import Network
import SwiftData
import os

/// Monitors network connectivity type and quality using NWPathMonitor.
@Observable
final class ConnectivityCollector: DataCollector {
    let id = "connectivity"
    let name = "Connectivity"
    let icon = "wifi"
    let description = "Wi-Fi, cellular, connection quality"

    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "ConnectivityCollector")
    private let modelContainer: ModelContainer
    private var monitor: NWPathMonitor?
    private let monitorQueue = DispatchQueue(label: "co.enix.ClawAntenna.connectivity")

    private(set) var isRunning = false
    var lastError: String?

    var isAvailable: Bool { true }
    var permissionStatus: CollectorPermissionStatus { .notRequired }

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func requestPermission() {}

    func start() {
        let m = NWPathMonitor()
        m.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let networkType: String
            if path.usesInterfaceType(.wifi) {
                networkType = "wifi"
            } else if path.usesInterfaceType(.cellular) {
                networkType = "cellular"
            } else if path.usesInterfaceType(.wiredEthernet) {
                networkType = "wired"
            } else {
                networkType = "none"
            }

            Task { @MainActor in
                self.recordConnectivity(networkType: networkType, isExpensive: path.isExpensive, isConstrained: path.isConstrained)
            }
        }
        m.start(queue: monitorQueue)
        monitor = m
        isRunning = true
        logger.info("Started connectivity monitoring")
    }

    func stop() {
        monitor?.cancel()
        monitor = nil
        isRunning = false
        logger.info("Stopped connectivity monitoring")
    }

    private func recordConnectivity(networkType: String, isExpensive: Bool, isConstrained: Bool) {
        let context = ModelContext(modelContainer)
        let record = ConnectivityRecord(networkType: networkType, isExpensive: isExpensive, isConstrained: isConstrained)
        context.insert(record)
        do {
            try context.save()
        } catch {
            lastError = error.localizedDescription
            logger.error("Failed to save connectivity record: \(error.localizedDescription)")
        }
    }
}
