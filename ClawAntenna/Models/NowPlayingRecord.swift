import Foundation
import SwiftData

@Model
final class NowPlayingRecord: Uploadable {
    static let supabaseTable = "now_playing"

    @Attribute(.unique) var id: UUID
    var title: String?
    var artist: String?
    var album: String?
    var playbackDuration: Double?
    var recordedAt: Date
    var uploadStatus: String
    var uploadAttempts: Int
    var lastUploadAttempt: Date?

    init(
        title: String?,
        artist: String?,
        album: String?,
        playbackDuration: Double?,
        recordedAt: Date = Date()
    ) {
        self.id = UUID()
        self.title = title
        self.artist = artist
        self.album = album
        self.playbackDuration = playbackDuration
        self.recordedAt = recordedAt
        self.uploadStatus = UploadStatus.pending.rawValue
        self.uploadAttempts = 0
    }

    func toSupabaseJSON() -> [String: Any] {
        var json: [String: Any] = [
            "id": id.uuidString,
            "recorded_at": ISO8601DateFormatter().string(from: recordedAt)
        ]
        if let title { json["title"] = title }
        if let artist { json["artist"] = artist }
        if let album { json["album"] = album }
        if let playbackDuration { json["playback_duration"] = playbackDuration }
        return json
    }
}
