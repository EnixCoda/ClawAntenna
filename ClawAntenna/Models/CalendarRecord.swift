import Foundation
import SwiftData

@Model
final class CalendarRecord: Uploadable {
    static let supabaseTable = "calendar"

    @Attribute(.unique) var id: UUID
    var eventCount: Int
    var allDayCount: Int
    var recordedAt: Date
    var uploadStatus: String
    var uploadAttempts: Int
    var lastUploadAttempt: Date?

    init(eventCount: Int, allDayCount: Int, recordedAt: Date = Date()) {
        self.id = UUID()
        self.eventCount = eventCount
        self.allDayCount = allDayCount
        self.recordedAt = recordedAt
        self.uploadStatus = UploadStatus.pending.rawValue
        self.uploadAttempts = 0
    }

    func toSupabaseJSON() -> [String: Any] {
        [
            "id": id.uuidString,
            "event_count": eventCount,
            "all_day_count": allDayCount,
            "recorded_at": ISO8601DateFormatter().string(from: recordedAt)
        ]
    }
}
