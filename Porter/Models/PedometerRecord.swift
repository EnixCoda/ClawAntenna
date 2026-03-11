import Foundation
import SwiftData

@Model
final class PedometerRecord: Uploadable {
    static let supabaseTable = "pedometer"

    @Attribute(.unique) var id: UUID
    var steps: Int
    var distance: Double?
    var floorsAscended: Int?
    var floorsDescended: Int?
    var cadence: Double?
    var periodStart: Date
    var periodEnd: Date
    var uploadStatus: String
    var uploadAttempts: Int
    var lastUploadAttempt: Date?

    init(
        steps: Int,
        distance: Double? = nil,
        floorsAscended: Int? = nil,
        floorsDescended: Int? = nil,
        cadence: Double? = nil,
        periodStart: Date,
        periodEnd: Date
    ) {
        self.id = UUID()
        self.steps = steps
        self.distance = distance
        self.floorsAscended = floorsAscended
        self.floorsDescended = floorsDescended
        self.cadence = cadence
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.uploadStatus = UploadStatus.pending.rawValue
        self.uploadAttempts = 0
    }

    func toSupabaseJSON() -> [String: Any] {
        var json: [String: Any] = [
            "id": id.uuidString,
            "steps": steps,
            "period_start": ISO8601DateFormatter().string(from: periodStart),
            "period_end": ISO8601DateFormatter().string(from: periodEnd)
        ]
        if let distance { json["distance"] = distance }
        if let floorsAscended { json["floors_ascended"] = floorsAscended }
        if let floorsDescended { json["floors_descended"] = floorsDescended }
        if let cadence { json["cadence"] = cadence }
        return json
    }
}
