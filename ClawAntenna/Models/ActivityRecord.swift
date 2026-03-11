import Foundation
import SwiftData

@Model
final class ActivityRecord: Uploadable {
    static let supabaseTable = "activities"

    @Attribute(.unique) var id: UUID
    var activityType: String
    var confidence: String
    var startedAt: Date
    var recordedAt: Date
    var uploadStatus: String
    var uploadAttempts: Int
    var lastUploadAttempt: Date?

    init(
        activityType: String,
        confidence: String,
        startedAt: Date,
        recordedAt: Date = Date()
    ) {
        self.id = UUID()
        self.activityType = activityType
        self.confidence = confidence
        self.startedAt = startedAt
        self.recordedAt = recordedAt
        self.uploadStatus = UploadStatus.pending.rawValue
        self.uploadAttempts = 0
    }

    func toSupabaseJSON() -> [String: Any] {
        [
            "id": id.uuidString,
            "activity_type": activityType,
            "confidence": confidence,
            "started_at": ISO8601DateFormatter().string(from: startedAt),
            "recorded_at": ISO8601DateFormatter().string(from: recordedAt)
        ]
    }
}
