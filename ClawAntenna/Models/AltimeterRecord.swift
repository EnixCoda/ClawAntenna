import Foundation
import SwiftData

@Model
final class AltimeterRecord: Uploadable {
    static let supabaseTable = "altimeter"

    @Attribute(.unique) var id: UUID
    var pressure: Double
    var relativeAltitude: Double?
    var recordedAt: Date
    var uploadStatus: String
    var uploadAttempts: Int
    var lastUploadAttempt: Date?

    init(
        pressure: Double,
        relativeAltitude: Double? = nil,
        recordedAt: Date = Date()
    ) {
        self.id = UUID()
        self.pressure = pressure
        self.relativeAltitude = relativeAltitude
        self.recordedAt = recordedAt
        self.uploadStatus = UploadStatus.pending.rawValue
        self.uploadAttempts = 0
    }

    func toSupabaseJSON() -> [String: Any] {
        var json: [String: Any] = [
            "id": id.uuidString,
            "pressure": pressure,
            "recorded_at": ISO8601DateFormatter().string(from: recordedAt)
        ]
        if let relativeAltitude { json["relative_altitude"] = relativeAltitude }
        return json
    }
}
