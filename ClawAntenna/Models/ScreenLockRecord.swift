import Foundation
import SwiftData

@Model
final class ScreenLockRecord: Uploadable {
    static let supabaseTable = "screen_lock"

    @Attribute(.unique) var id: UUID
    var isLocked: Bool
    var recordedAt: Date
    var uploadStatus: String
    var uploadAttempts: Int
    var lastUploadAttempt: Date?

    init(isLocked: Bool, recordedAt: Date = Date()) {
        self.id = UUID()
        self.isLocked = isLocked
        self.recordedAt = recordedAt
        self.uploadStatus = UploadStatus.pending.rawValue
        self.uploadAttempts = 0
    }

    func toSupabaseJSON() -> [String: Any] {
        [
            "id": id.uuidString,
            "is_locked": isLocked,
            "recorded_at": ISO8601DateFormatter().string(from: recordedAt)
        ]
    }
}
