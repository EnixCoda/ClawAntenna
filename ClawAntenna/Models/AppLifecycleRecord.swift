import Foundation
import SwiftData

@Model
final class AppLifecycleRecord: Uploadable {
    static let supabaseTable = "app_lifecycle"

    @Attribute(.unique) var id: UUID
    var event: String
    var recordedAt: Date
    var uploadStatus: String
    var uploadAttempts: Int
    var lastUploadAttempt: Date?

    init(event: String, recordedAt: Date = Date()) {
        self.id = UUID()
        self.event = event
        self.recordedAt = recordedAt
        self.uploadStatus = UploadStatus.pending.rawValue
        self.uploadAttempts = 0
    }

    func toSupabaseJSON() -> [String: Any] {
        [
            "id": id.uuidString,
            "event": event,
            "recorded_at": ISO8601DateFormatter().string(from: recordedAt)
        ]
    }
}
