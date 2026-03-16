import Foundation
import MediaPlayer
import SwiftData
import os

/// Tracks the currently playing media track.
/// Event-driven — records when the now-playing item changes.
@Observable
final class NowPlayingCollector: DataCollector {
    let id = "nowplaying"
    let name = "Now Playing"
    let icon = "music.note"
    let description = "Currently playing track, artist, album"

    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "NowPlayingCollector")
    private let modelContainer: ModelContainer
    private var observer: NSObjectProtocol?

    private(set) var isRunning = false
    var lastError: String?

    var isAvailable: Bool { true }
    var permissionStatus: CollectorPermissionStatus { .notRequired }

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func requestPermission() {}
    func refreshPermissionStatus() {}

    func start() {
        observer = NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.recordNowPlaying() }
        }

        // Enable notifications from the system music player
        MPMusicPlayerController.systemMusicPlayer.beginGeneratingPlaybackNotifications()

        recordNowPlaying()
        isRunning = true
        logger.info("Started now-playing monitoring")
    }

    func stop() {
        if let observer { NotificationCenter.default.removeObserver(observer) }
        observer = nil
        MPMusicPlayerController.systemMusicPlayer.endGeneratingPlaybackNotifications()
        isRunning = false
        logger.info("Stopped now-playing monitoring")
    }

    private func recordNowPlaying() {
        guard let item = MPMusicPlayerController.systemMusicPlayer.nowPlayingItem else {
            return
        }

        let title = item.title
        let artist = item.artist
        let album = item.albumTitle
        let duration = item.playbackDuration

        let context = ModelContext(modelContainer)
        let record = NowPlayingRecord(
            title: title,
            artist: artist,
            album: album,
            playbackDuration: duration > 0 ? duration : nil
        )
        context.insert(record)
        do {
            try context.save()
        } catch {
            lastError = error.localizedDescription
            logger.error("Failed to save now-playing record: \(error.localizedDescription)")
        }
    }
}
