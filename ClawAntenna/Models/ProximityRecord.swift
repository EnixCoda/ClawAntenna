import Foundation
import SwiftData

@Model
final class ProximityRecord: Uploadable {
    static let supabaseTable = "proximity"

    @Attribute(.unique) var id: UUID
    var isNear: Bool
    var recordedAt: Date
    var uploadStatus: String
    var uploadAttempts: Int
    var lastUploadAttempt: Date?

    init(isNear: Bool, recordedAt: Date = Date()) {
        self.id = UUID()
        self.isNear = isNear
        self.recordedAt = recordedAt
        self.uploadStatus = UploadStatus.pending.rawValue
        self.uploadAttempts = 0
    }

    func toSupabaseJSON() -> [String: Any] {
        [
            "id": id.uuidString,
            "is_near": isNear,
            "recorded_at": ISO8601DateFormatter().string(from: recordedAt)
        ]
    }
}
