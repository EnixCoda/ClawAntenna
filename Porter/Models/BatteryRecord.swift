import Foundation
import SwiftData

@Model
final class BatteryRecord: Uploadable {
    static let supabaseTable = "battery"

    @Attribute(.unique) var id: UUID
    var level: Double
    var state: String
    var recordedAt: Date
    var uploadStatus: String
    var uploadAttempts: Int
    var lastUploadAttempt: Date?

    init(
        level: Double,
        state: String,
        recordedAt: Date = Date()
    ) {
        self.id = UUID()
        self.level = level
        self.state = state
        self.recordedAt = recordedAt
        self.uploadStatus = UploadStatus.pending.rawValue
        self.uploadAttempts = 0
    }

    func toSupabaseJSON() -> [String: Any] {
        [
            "id": id.uuidString,
            "level": level,
            "state": state,
            "recorded_at": ISO8601DateFormatter().string(from: recordedAt)
        ]
    }
}
