import Foundation
import SwiftData

@Model
final class BrightnessRecord: Uploadable {
    static let supabaseTable = "brightness"

    @Attribute(.unique) var id: UUID
    var level: Double
    var recordedAt: Date
    var uploadStatus: String
    var uploadAttempts: Int
    var lastUploadAttempt: Date?

    init(
        level: Double,
        recordedAt: Date = Date()
    ) {
        self.id = UUID()
        self.level = level
        self.recordedAt = recordedAt
        self.uploadStatus = UploadStatus.pending.rawValue
        self.uploadAttempts = 0
    }

    func toSupabaseJSON() -> [String: Any] {
        [
            "id": id.uuidString,
            "level": level,
            "recorded_at": ISO8601DateFormatter().string(from: recordedAt)
        ]
    }
}
