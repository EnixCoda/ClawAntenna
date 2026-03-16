import Foundation
import SwiftData

@Model
final class StorageRecord: Uploadable {
    static let supabaseTable = "storage"

    @Attribute(.unique) var id: UUID
    var totalBytes: Int64
    var availableBytes: Int64
    var recordedAt: Date
    var uploadStatus: String
    var uploadAttempts: Int
    var lastUploadAttempt: Date?

    init(
        totalBytes: Int64,
        availableBytes: Int64,
        recordedAt: Date = Date()
    ) {
        self.id = UUID()
        self.totalBytes = totalBytes
        self.availableBytes = availableBytes
        self.recordedAt = recordedAt
        self.uploadStatus = UploadStatus.pending.rawValue
        self.uploadAttempts = 0
    }

    func toSupabaseJSON() -> [String: Any] {
        [
            "id": id.uuidString,
            "total_bytes": totalBytes,
            "available_bytes": availableBytes,
            "recorded_at": ISO8601DateFormatter().string(from: recordedAt)
        ]
    }
}
