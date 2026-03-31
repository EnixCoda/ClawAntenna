import Foundation
import SwiftData

@Model
final class GeofenceRecord: Uploadable {
    static let supabaseTable = "geofence"

    @Attribute(.unique) var id: UUID
    var regionIdentifier: String
    var event: String
    var recordedAt: Date
    var uploadStatus: String
    var uploadAttempts: Int
    var lastUploadAttempt: Date?

    init(regionIdentifier: String, event: String, recordedAt: Date = Date()) {
        self.id = UUID()
        self.regionIdentifier = regionIdentifier
        self.event = event
        self.recordedAt = recordedAt
        self.uploadStatus = UploadStatus.pending.rawValue
        self.uploadAttempts = 0
    }

    func toSupabaseJSON() -> [String: Any] {
        [
            "id": id.uuidString,
            "region_identifier": regionIdentifier,
            "event": event,
            "recorded_at": ISO8601DateFormatter().string(from: recordedAt)
        ]
    }
}
