import Foundation
import SwiftData

@Model
final class VisitRecord: Uploadable {
    static let supabaseTable = "visits"

    @Attribute(.unique) var id: UUID
    var latitude: Double
    var longitude: Double
    var horizontalAccuracy: Double
    var arrivalAt: Date?
    var departureAt: Date?
    var recordedAt: Date
    var uploadStatus: String
    var uploadAttempts: Int
    var lastUploadAttempt: Date?

    init(
        latitude: Double,
        longitude: Double,
        horizontalAccuracy: Double,
        arrivalAt: Date?,
        departureAt: Date?,
        recordedAt: Date = Date()
    ) {
        self.id = UUID()
        self.latitude = latitude
        self.longitude = longitude
        self.horizontalAccuracy = horizontalAccuracy
        self.arrivalAt = arrivalAt
        self.departureAt = departureAt
        self.recordedAt = recordedAt
        self.uploadStatus = UploadStatus.pending.rawValue
        self.uploadAttempts = 0
    }

    func toSupabaseJSON() -> [String: Any] {
        let fmt = ISO8601DateFormatter()
        var json: [String: Any] = [
            "id": id.uuidString,
            "latitude": latitude,
            "longitude": longitude,
            "horizontal_accuracy": horizontalAccuracy,
            "recorded_at": fmt.string(from: recordedAt)
        ]
        if let arrivalAt { json["arrival_at"] = fmt.string(from: arrivalAt) }
        if let departureAt { json["departure_at"] = fmt.string(from: departureAt) }
        return json
    }
}
