import Foundation
import AVFAudio
import SwiftData
import os

/// Measures ambient sound level in decibels using the device microphone.
/// No audio is recorded or stored — only the decibel level.
@Observable
final class NoiseCollector: DataCollector {
    let id = "noise"
    let name = "Noise"
    let icon = "waveform"
    let description = "Ambient sound level in decibels"

    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "NoiseCollector")
    private let modelContainer: ModelContainer
    private var audioEngine: AVAudioEngine?
    private var timer: Timer?
    private var latestDecibels: Double = -160.0
    private var latestPeak: Double = -160.0
    private var pendingStart = false

    private(set) var isRunning = false
    var lastError: String?

    var isAvailable: Bool { true }

    private(set) var permissionStatus: CollectorPermissionStatus = .notDetermined

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        refreshPermissionStatus()
    }

    func refreshPermissionStatus() {
        permissionStatus = switch AVAudioApplication.shared.recordPermission {
        case .undetermined: .notDetermined
        case .denied: .denied
        case .granted: .authorized
        @unknown default: .notDetermined
        }
    }

    func requestPermission() {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            guard let self else { return }
            Task { @MainActor in
                self.refreshPermissionStatus()
                if self.pendingStart {
                    self.start()
                }
            }
        }
    }

    func start() {
        if permissionStatus == .notDetermined {
            pendingStart = true
            requestPermission()
            return
        }
        guard permissionStatus.isGranted else {
            logger.warning("Cannot start without microphone permission")
            pendingStart = false
            return
        }
        pendingStart = false

        do {
            let engine = AVAudioEngine()
            let inputNode = engine.inputNode
            let format = inputNode.outputFormat(forBus: 0)

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                guard let self else { return }
                let channelData = buffer.floatChannelData?[0]
                let frameLength = Int(buffer.frameLength)
                guard let data = channelData, frameLength > 0 else { return }

                var sumSquares: Float = 0
                var peak: Float = 0
                for i in 0..<frameLength {
                    let sample = data[i]
                    sumSquares += sample * sample
                    peak = max(peak, abs(sample))
                }
                let rms = sqrt(sumSquares / Float(frameLength))
                let db = 20 * log10(max(rms, 1e-10))
                let peakDb = 20 * log10(max(peak, 1e-10))

                Task { @MainActor [weak self] in
                    self?.latestDecibels = Double(db)
                    self?.latestPeak = Double(peakDb)
                }
            }

            try engine.start()
            self.audioEngine = engine

            // Sample and persist every 60 seconds
            timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in self.recordNoise() }
            }

            isRunning = true
            logger.info("Started noise monitoring")
        } catch {
            lastError = error.localizedDescription
            logger.error("Failed to start audio engine: \(error.localizedDescription)")
        }
    }

    func stop() {
        pendingStart = false
        timer?.invalidate()
        timer = nil
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        isRunning = false
        logger.info("Stopped noise monitoring")
    }

    private func recordNoise() {
        let context = ModelContext(modelContainer)
        let record = NoiseRecord(
            decibels: latestDecibels,
            peakDecibels: latestPeak > -160.0 ? latestPeak : nil
        )
        context.insert(record)
        do {
            try context.save()
        } catch {
            lastError = error.localizedDescription
            logger.error("Failed to save noise record: \(error.localizedDescription)")
        }
    }
}
