import Foundation
import SwiftData

@Model
final class ConnectivityRecord: Uploadable {
    static let supabaseTable = "connectivity"

    @Attribute(.unique) var id: UUID
    var networkType: String
    var isExpensive: Bool
    var isConstrained: Bool
    var recordedAt: Date
    var uploadStatus: String
    var uploadAttempts: Int
    var lastUploadAttempt: Date?

    init(
        networkType: String,
        isExpensive: Bool = false,
        isConstrained: Bool = false,
        recordedAt: Date = Date()
    ) {
        self.id = UUID()
        self.networkType = networkType
        self.isExpensive = isExpensive
        self.isConstrained = isConstrained
        self.recordedAt = recordedAt
        self.uploadStatus = UploadStatus.pending.rawValue
        self.uploadAttempts = 0
    }

    func toSupabaseJSON() -> [String: Any] {
        [
            "id": id.uuidString,
            "network_type": networkType,
            "is_expensive": isExpensive,
            "is_constrained": isConstrained,
            "recorded_at": ISO8601DateFormatter().string(from: recordedAt)
        ]
    }
}
