import Foundation
import SwiftData

@Model
final class MemoryRecord: Uploadable {
    static let supabaseTable = "memory"

    @Attribute(.unique) var id: UUID
    var availableBytes: Int64
    var totalBytes: Int64
    var recordedAt: Date
    var uploadStatus: String
    var uploadAttempts: Int
    var lastUploadAttempt: Date?

    init(availableBytes: Int64, totalBytes: Int64, recordedAt: Date = Date()) {
        self.id = UUID()
        self.availableBytes = availableBytes
        self.totalBytes = totalBytes
        self.recordedAt = recordedAt
        self.uploadStatus = UploadStatus.pending.rawValue
        self.uploadAttempts = 0
    }

    func toSupabaseJSON() -> [String: Any] {
        [
            "id": id.uuidString,
            "available_bytes": availableBytes,
            "total_bytes": totalBytes,
            "recorded_at": ISO8601DateFormatter().string(from: recordedAt)
        ]
    }
}
