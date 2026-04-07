import Foundation
import CoreTelephony
import SwiftData
import os

/// Monitors cellular radio access technology changes (5G, LTE, 3G, etc.).
@Observable
final class CellularCollector: DataCollector {
    let id = "cellular"
    let name = "Cellular"
    let icon = "antenna.radiowaves.left.and.right.circle"
    let description = "Carrier name, radio type (5G/LTE/3G)"

    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "CellularCollector")
    private let modelContainer: ModelContainer
    private let networkInfo = CTTelephonyNetworkInfo()
    private var observer: NSObjectProtocol?
    private var lastRadioType: String?

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
        observer = NotificationCenter.default.addObserver(
            forName: .CTServiceRadioAccessTechnologyDidChange,
            object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.recordCellular() }
        }

        recordCellular()
        isRunning = true
        logger.info("Started cellular monitoring")
    }

    func stop() {
        if let observer { NotificationCenter.default.removeObserver(observer) }
        observer = nil
        isRunning = false
        lastRadioType = nil
        logger.info("Stopped cellular monitoring")
    }

    private func recordCellular() {
        let radioMap = networkInfo.serviceCurrentRadioAccessTechnology
        let radioType = radioMap?.values.first.map { friendlyName(for: $0) } ?? "none"

        guard radioType != lastRadioType else { return }
        lastRadioType = radioType

        let carrierName: String? = nil // CTCarrier is deprecated in iOS 16+

        let context = ModelContext(modelContainer)
        let record = CellularRecord(carrierName: carrierName, radioType: radioType)
        context.insert(record)
        do {
            try context.save()
        } catch {
            lastError = error.localizedDescription
            logger.error("Failed to save cellular record: \(error.localizedDescription)")
        }
    }

    private func friendlyName(for technology: String) -> String {
        switch technology {
        case CTRadioAccessTechnologyLTE: return "LTE"
        case CTRadioAccessTechnologyeHRPD: return "eHRPD"
        case CTRadioAccessTechnologyHSDPA: return "HSDPA"
        case CTRadioAccessTechnologyHSUPA: return "HSUPA"
        case CTRadioAccessTechnologyWCDMA: return "WCDMA"
        case CTRadioAccessTechnologyEdge: return "EDGE"
        case CTRadioAccessTechnologyGPRS: return "GPRS"
        case CTRadioAccessTechnologyCDMA1x: return "CDMA"
        case CTRadioAccessTechnologyCDMAEVDORev0: return "EVDO_0"
        case CTRadioAccessTechnologyCDMAEVDORevA: return "EVDO_A"
        case CTRadioAccessTechnologyCDMAEVDORevB: return "EVDO_B"
        default:
            if #available(iOS 14.1, *) {
                if technology == CTRadioAccessTechnologyNRNSA { return "5G_NSA" }
                if technology == CTRadioAccessTechnologyNR { return "5G" }
            }
            return technology
        }
    }
}
