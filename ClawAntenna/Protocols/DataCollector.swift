import Foundation

/// Permission state for a data collector.
enum CollectorPermissionStatus: String {
    case notRequired
    case notDetermined
    case authorized
    case limited
    case denied
    case restricted

    var displayName: String {
        switch self {
        case .notRequired: "Not Required"
        case .notDetermined: "Not Requested"
        case .authorized: "Authorized"
        case .limited: "Limited"
        case .denied: "Denied"
        case .restricted: "Restricted"
        }
    }

    var isGranted: Bool {
        self == .authorized || self == .notRequired || self == .limited
    }
}

/// Common interface for all data collectors in ClawAntenna.
///
/// Each collector is responsible for a single data source (location, motion, battery, etc.)
/// and manages its own permission lifecycle and background collection.
@MainActor
protocol DataCollector: AnyObject, Observable {
    /// Unique identifier for this collector (e.g., "location", "pedometer").
    var id: String { get }

    /// Human-readable name (e.g., "Location", "Pedometer").
    var name: String { get }

    /// SF Symbol name for the collector's icon.
    var icon: String { get }

    /// Short description of what this collector captures.
    var description: String { get }

    /// Whether the required hardware/framework is available on this device.
    var isAvailable: Bool { get }

    /// Whether the collector is actively collecting data.
    var isRunning: Bool { get }

    /// Current permission status. Must be a stored property for UI reactivity.
    var permissionStatus: CollectorPermissionStatus { get }

    /// Most recent error, if any.
    var lastError: String? { get }

    /// Re-read the OS permission state and update the stored `permissionStatus`.
    /// Call after returning from Settings or after the OS permission dialog dismisses.
    func refreshPermissionStatus()

    /// Request the required OS permission for this collector.
    func requestPermission()

    /// Start collecting data. If permission is needed and not yet granted,
    /// requests permission and starts automatically once granted.
    func start()

    /// Stop collecting data. No-op if already stopped.
    func stop()
}
