import Foundation
import SwiftData

/// Retained in schema for backward compatibility with existing databases.
/// No new records are created — the Bluetooth collector has been removed.
@Model
final class BluetoothRecord: Uploadable {
    static let supabaseTable = "bluetooth"

    @Attribute(.unique) var id: UUID
    var peripheralName: String?
    var peripheralUUID: String
    var rssi: Int
    var recordedAt: Date
    var uploadStatus: String
    var uploadAttempts: Int
    var lastUploadAttempt: Date?

    init(peripheralName: String?, peripheralUUID: String, rssi: Int) {
        self.id = UUID()
        self.peripheralName = peripheralName
        self.peripheralUUID = peripheralUUID
        self.rssi = rssi
        self.recordedAt = Date()
        self.uploadStatus = UploadStatus.pending.rawValue
        self.uploadAttempts = 0
        self.lastUploadAttempt = nil
    }

    func toSupabaseJSON() -> [String: Any] {
        var json: [String: Any] = [
            "id": id.uuidString,
            "peripheral_uuid": peripheralUUID,
            "rssi": rssi,
            "recorded_at": ISO8601DateFormatter().string(from: recordedAt)
        ]
        if let peripheralName { json["peripheral_name"] = peripheralName }
        return json
    }
}
