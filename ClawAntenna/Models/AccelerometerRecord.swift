import Foundation
import SwiftData

@Model
final class AccelerometerRecord: Uploadable {
    static let supabaseTable = "accelerometer"

    @Attribute(.unique) var id: UUID
    var x: Double
    var y: Double
    var z: Double
    var recordedAt: Date
    var uploadStatus: String
    var uploadAttempts: Int
    var lastUploadAttempt: Date?

    init(x: Double, y: Double, z: Double, recordedAt: Date = Date()) {
        self.id = UUID()
        self.x = x
        self.y = y
        self.z = z
        self.recordedAt = recordedAt
        self.uploadStatus = UploadStatus.pending.rawValue
        self.uploadAttempts = 0
    }

    func toSupabaseJSON() -> [String: Any] {
        [
            "id": id.uuidString,
            "x": x,
            "y": y,
            "z": z,
            "recorded_at": ISO8601DateFormatter().string(from: recordedAt)
        ]
    }
}
