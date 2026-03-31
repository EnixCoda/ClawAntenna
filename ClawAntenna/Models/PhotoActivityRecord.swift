import Foundation
import SwiftData

@Model
final class PhotoActivityRecord: Uploadable {
    static let supabaseTable = "photo_activity"

    @Attribute(.unique) var id: UUID
    var photoCount: Int
    var videoCount: Int
    var recordedAt: Date
    var uploadStatus: String
    var uploadAttempts: Int
    var lastUploadAttempt: Date?

    init(photoCount: Int, videoCount: Int, recordedAt: Date = Date()) {
        self.id = UUID()
        self.photoCount = photoCount
        self.videoCount = videoCount
        self.recordedAt = recordedAt
        self.uploadStatus = UploadStatus.pending.rawValue
        self.uploadAttempts = 0
    }

    func toSupabaseJSON() -> [String: Any] {
        [
            "id": id.uuidString,
            "photo_count": photoCount,
            "video_count": videoCount,
            "recorded_at": ISO8601DateFormatter().string(from: recordedAt)
        ]
    }
}
