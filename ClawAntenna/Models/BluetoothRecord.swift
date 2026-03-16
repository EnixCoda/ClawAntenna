import Foundation
import SwiftData

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

    init(
        peripheralName: String?,
        peripheralUUID: String,
        rssi: Int,
        recordedAt: Date = Date()
    ) {
        self.id = UUID()
        self.peripheralName = peripheralName
        self.peripheralUUID = peripheralUUID
        self.rssi = rssi
        self.recordedAt = recordedAt
        self.uploadStatus = UploadStatus.pending.rawValue
        self.uploadAttempts = 0
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
