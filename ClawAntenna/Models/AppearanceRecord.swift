import Foundation
import SwiftData

@Model
final class AppearanceRecord: Uploadable {
    static let supabaseTable = "appearance"

    @Attribute(.unique) var id: UUID
    var style: String
    var recordedAt: Date
    var uploadStatus: String
    var uploadAttempts: Int
    var lastUploadAttempt: Date?

    init(style: String, recordedAt: Date = Date()) {
        self.id = UUID()
        self.style = style
        self.recordedAt = recordedAt
        self.uploadStatus = UploadStatus.pending.rawValue
        self.uploadAttempts = 0
    }

    func toSupabaseJSON() -> [String: Any] {
        [
            "id": id.uuidString,
            "style": style,
            "recorded_at": ISO8601DateFormatter().string(from: recordedAt)
        ]
    }
}
