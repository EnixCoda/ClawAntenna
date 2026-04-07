import Foundation
import SwiftData

@Model
final class CellularRecord: Uploadable {
    static let supabaseTable = "cellular"

    @Attribute(.unique) var id: UUID
    var carrierName: String?
    var radioType: String
    var recordedAt: Date
    var uploadStatus: String
    var uploadAttempts: Int
    var lastUploadAttempt: Date?

    init(carrierName: String?, radioType: String, recordedAt: Date = Date()) {
        self.id = UUID()
        self.carrierName = carrierName
        self.radioType = radioType
        self.recordedAt = recordedAt
        self.uploadStatus = UploadStatus.pending.rawValue
        self.uploadAttempts = 0
    }

    func toSupabaseJSON() -> [String: Any] {
        var json: [String: Any] = [
            "id": id.uuidString,
            "radio_type": radioType,
            "recorded_at": ISO8601DateFormatter().string(from: recordedAt)
        ]
        if let carrierName { json["carrier_name"] = carrierName }
        return json
    }
}
