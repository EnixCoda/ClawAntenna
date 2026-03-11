import Foundation
import SwiftData

@Model
final class HealthRecord: Uploadable {
    static let supabaseTable = "health"

    @Attribute(.unique) var id: UUID
    var metricType: String
    var value: Double?
    var unit: String?
    var startedAt: Date?
    var endedAt: Date?
    var recordedAt: Date
    var uploadStatus: String
    var uploadAttempts: Int
    var lastUploadAttempt: Date?

    init(
        metricType: String,
        value: Double? = nil,
        unit: String? = nil,
        startedAt: Date? = nil,
        endedAt: Date? = nil,
        recordedAt: Date = Date()
    ) {
        self.id = UUID()
        self.metricType = metricType
        self.value = value
        self.unit = unit
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.recordedAt = recordedAt
        self.uploadStatus = UploadStatus.pending.rawValue
        self.uploadAttempts = 0
    }

    func toSupabaseJSON() -> [String: Any] {
        var json: [String: Any] = [
            "id": id.uuidString,
            "metric_type": metricType,
            "recorded_at": ISO8601DateFormatter().string(from: recordedAt)
        ]
        if let value { json["value"] = value }
        if let unit { json["unit"] = unit }
        if let startedAt { json["started_at"] = ISO8601DateFormatter().string(from: startedAt) }
        if let endedAt { json["ended_at"] = ISO8601DateFormatter().string(from: endedAt) }
        return json
    }
}
