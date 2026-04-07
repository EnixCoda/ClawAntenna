import Foundation
import SwiftData

@Model
final class LowPowerRecord: Uploadable {
    static let supabaseTable = "low_power"

    @Attribute(.unique) var id: UUID
    var isEnabled: Bool
    var recordedAt: Date
    var uploadStatus: String
    var uploadAttempts: Int
    var lastUploadAttempt: Date?

    init(isEnabled: Bool, recordedAt: Date = Date()) {
        self.id = UUID()
        self.isEnabled = isEnabled
        self.recordedAt = recordedAt
        self.uploadStatus = UploadStatus.pending.rawValue
        self.uploadAttempts = 0
    }

    func toSupabaseJSON() -> [String: Any] {
        [
            "id": id.uuidString,
            "is_enabled": isEnabled,
            "recorded_at": ISO8601DateFormatter().string(from: recordedAt)
        ]
    }
}
