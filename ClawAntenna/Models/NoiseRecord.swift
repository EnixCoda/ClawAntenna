import Foundation
import SwiftData

@Model
final class NoiseRecord: Uploadable {
    static let supabaseTable = "noise"

    @Attribute(.unique) var id: UUID
    var decibels: Double
    var peakDecibels: Double?
    var recordedAt: Date
    var uploadStatus: String
    var uploadAttempts: Int
    var lastUploadAttempt: Date?

    init(
        decibels: Double,
        peakDecibels: Double?,
        recordedAt: Date = Date()
    ) {
        self.id = UUID()
        self.decibels = decibels
        self.peakDecibels = peakDecibels
        self.recordedAt = recordedAt
        self.uploadStatus = UploadStatus.pending.rawValue
        self.uploadAttempts = 0
    }

    func toSupabaseJSON() -> [String: Any] {
        var json: [String: Any] = [
            "id": id.uuidString,
            "decibels": decibels,
            "recorded_at": ISO8601DateFormatter().string(from: recordedAt)
        ]
        if let peakDecibels { json["peak_decibels"] = peakDecibels }
        return json
    }
}
