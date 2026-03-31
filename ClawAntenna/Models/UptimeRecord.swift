import Foundation
import SwiftData

@Model
final class UptimeRecord: Uploadable {
    static let supabaseTable = "uptime"

    @Attribute(.unique) var id: UUID
    var uptimeSeconds: Double
    var recordedAt: Date
    var uploadStatus: String
    var uploadAttempts: Int
    var lastUploadAttempt: Date?

    init(uptimeSeconds: Double, recordedAt: Date = Date()) {
        self.id = UUID()
        self.uptimeSeconds = uptimeSeconds
        self.recordedAt = recordedAt
        self.uploadStatus = UploadStatus.pending.rawValue
        self.uploadAttempts = 0
    }

    func toSupabaseJSON() -> [String: Any] {
        [
            "id": id.uuidString,
            "uptime_seconds": uptimeSeconds,
            "recorded_at": ISO8601DateFormatter().string(from: recordedAt)
        ]
    }
}
