import Foundation
import SwiftData

enum UploadStatus: String, Codable {
    case pending
    case uploading
    case uploaded
    case failed
}

@Model
final class LocationRecord {
    @Attribute(.unique) var id: UUID
    var latitude: Double
    var longitude: Double
    var altitude: Double
    var horizontalAccuracy: Double
    var speed: Double
    var recordedAt: Date
    var uploadStatus: String
    var uploadAttempts: Int
    var lastUploadAttempt: Date?

    init(
        latitude: Double,
        longitude: Double,
        altitude: Double,
        horizontalAccuracy: Double,
        speed: Double,
        recordedAt: Date
    ) {
        self.id = UUID()
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.speed = speed
        self.recordedAt = recordedAt
        self.uploadStatus = UploadStatus.pending.rawValue
        self.uploadAttempts = 0
        self.lastUploadAttempt = nil
    }

    var status: UploadStatus {
        get { UploadStatus(rawValue: uploadStatus) ?? .pending }
        set { uploadStatus = newValue.rawValue }
    }

    /// Converts to the JSON dictionary format expected by Supabase REST API.
    func toSupabaseJSON() -> [String: Any] {
        let json: [String: Any] = [
            "id": id.uuidString,
            "latitude": latitude,
            "longitude": longitude,
            "altitude": altitude,
            "horizontal_accuracy": horizontalAccuracy,
            "speed": speed,
            "recorded_at": ISO8601DateFormatter().string(from: recordedAt)
        ]
        return json
    }
}
