import Foundation
import SwiftData

@Model
final class TimezoneRecord: Uploadable {
    static let supabaseTable = "timezone"

    @Attribute(.unique) var id: UUID
    var identifier: String
    var abbreviation: String?
    var secondsFromGMT: Int
    var recordedAt: Date
    var uploadStatus: String
    var uploadAttempts: Int
    var lastUploadAttempt: Date?

    init(identifier: String, abbreviation: String?, secondsFromGMT: Int, recordedAt: Date = Date()) {
        self.id = UUID()
        self.identifier = identifier
        self.abbreviation = abbreviation
        self.secondsFromGMT = secondsFromGMT
        self.recordedAt = recordedAt
        self.uploadStatus = UploadStatus.pending.rawValue
        self.uploadAttempts = 0
    }

    func toSupabaseJSON() -> [String: Any] {
        var json: [String: Any] = [
            "id": id.uuidString,
            "identifier": identifier,
            "seconds_from_gmt": secondsFromGMT,
            "recorded_at": ISO8601DateFormatter().string(from: recordedAt)
        ]
        if let abbreviation { json["abbreviation"] = abbreviation }
        return json
    }
}
