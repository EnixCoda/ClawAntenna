import Foundation
import SwiftData

@Model
final class CompassRecord: Uploadable {
    static let supabaseTable = "compass"

    @Attribute(.unique) var id: UUID
    var magneticHeading: Double
    var trueHeading: Double?
    var headingAccuracy: Double?
    var recordedAt: Date
    var uploadStatus: String
    var uploadAttempts: Int
    var lastUploadAttempt: Date?

    init(
        magneticHeading: Double,
        trueHeading: Double?,
        headingAccuracy: Double?,
        recordedAt: Date = Date()
    ) {
        self.id = UUID()
        self.magneticHeading = magneticHeading
        self.trueHeading = trueHeading
        self.headingAccuracy = headingAccuracy
        self.recordedAt = recordedAt
        self.uploadStatus = UploadStatus.pending.rawValue
        self.uploadAttempts = 0
    }

    func toSupabaseJSON() -> [String: Any] {
        let fmt = ISO8601DateFormatter()
        var json: [String: Any] = [
            "id": id.uuidString,
            "magnetic_heading": magneticHeading,
            "recorded_at": fmt.string(from: recordedAt)
        ]
        if let trueHeading { json["true_heading"] = trueHeading }
        if let headingAccuracy { json["heading_accuracy"] = headingAccuracy }
        return json
    }
}
