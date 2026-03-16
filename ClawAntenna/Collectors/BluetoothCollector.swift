import Foundation
import CoreBluetooth
import SwiftData
import os

/// Scans for nearby Bluetooth Low Energy peripherals.
/// Records peripheral name, UUID, and signal strength (RSSI).
@Observable
final class BluetoothCollector: NSObject, DataCollector {
    let id = "bluetooth"
    let name = "Bluetooth"
    let icon = "antenna.radiowaves.left.and.right"
    override var description: String { "Nearby BLE peripherals (name, signal strength)" }

    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "BluetoothCollector")
    private let modelContainer: ModelContainer
    private var centralManager: CBCentralManager?
    private var scanTimer: Timer?
    private var pendingStart = false
    private var managerReady = false

    private(set) var isRunning = false
    var lastError: String?

    var isAvailable: Bool {
        centralManager?.state == .poweredOn
    }

    private(set) var permissionStatus: CollectorPermissionStatus = .notDetermined

    override init() {
        fatalError("Use init(modelContainer:)")
    }

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        super.init()
        refreshPermissionStatus()
    }

    func refreshPermissionStatus() {
        permissionStatus = switch CBCentralManager.authorization {
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        case .allowedAlways: .authorized
        @unknown default: .notDetermined
        }
    }

    func requestPermission() {
        // Creating the CBCentralManager triggers the permission dialog
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
    }

    func start() {
        if permissionStatus == .notDetermined {
            pendingStart = true
            requestPermission()
            return
        }
        guard permissionStatus.isGranted else {
            logger.warning("Cannot start without Bluetooth permission")
            pendingStart = false
            return
        }
        pendingStart = false

        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }

        if centralManager?.state == .poweredOn {
            beginScanning()
        } else {
            managerReady = false
        }
    }

    func stop() {
        pendingStart = false
        scanTimer?.invalidate()
        scanTimer = nil
        centralManager?.stopScan()
        isRunning = false
        logger.info("Stopped Bluetooth scanning")
    }

    private func beginScanning() {
        // Scan for 10 seconds every 5 minutes
        performScan()
        scanTimer = Timer.scheduledTimer(withTimeInterval: 5 * 60, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.performScan() }
        }
        isRunning = true
        logger.info("Started Bluetooth scanning (every 5 min)")
    }

    private func performScan() {
        centralManager?.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ])
        // Stop scanning after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.centralManager?.stopScan()
        }
    }
}

extension BluetoothCollector: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            refreshPermissionStatus()
            if central.state == .poweredOn {
                managerReady = true
                if pendingStart || isRunning {
                    beginScanning()
                }
            }
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let name = peripheral.name
        let uuid = peripheral.identifier.uuidString
        let rssi = RSSI.intValue

        Task { @MainActor in
            let context = ModelContext(modelContainer)
            let record = BluetoothRecord(
                peripheralName: name,
                peripheralUUID: uuid,
                rssi: rssi
            )
            context.insert(record)
            do {
                try context.save()
            } catch {
                lastError = error.localizedDescription
                logger.error("Failed to save bluetooth record: \(error.localizedDescription)")
            }
        }
    }
}
