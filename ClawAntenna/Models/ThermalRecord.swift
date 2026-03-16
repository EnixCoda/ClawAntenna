import Foundation
import SwiftData

@Model
final class ThermalRecord: Uploadable {
    static let supabaseTable = "thermal"

    @Attribute(.unique) var id: UUID
    var state: String
    var recordedAt: Date
    var uploadStatus: String
    var uploadAttempts: Int
    var lastUploadAttempt: Date?

    init(
        state: String,
        recordedAt: Date = Date()
    ) {
        self.id = UUID()
        self.state = state
        self.recordedAt = recordedAt
        self.uploadStatus = UploadStatus.pending.rawValue
        self.uploadAttempts = 0
    }

    func toSupabaseJSON() -> [String: Any] {
        [
            "id": id.uuidString,
            "state": state,
            "recorded_at": ISO8601DateFormatter().string(from: recordedAt)
        ]
    }
}
