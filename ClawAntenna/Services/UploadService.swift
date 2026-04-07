import Foundation
import SwiftData
import os

@Observable
final class UploadService {
    private let logger = Logger(subsystem: "co.enix.ClawAntenna", category: "Upload")
    private let settings: AppSettings
    private let session = URLSession.shared

    var isUploading = false
    var lastError: String?
    var totalPendingCount = 0
    var totalUploadedCount = 0

    init(settings: AppSettings) {
        self.settings = settings
    }

    /// Recomputes aggregate pending / uploaded counts across all record types.
    @MainActor
    func refreshCounts(modelContext: ModelContext) {
        var pending = 0
        var uploaded = 0

        func count<T: PersistentModel & Uploadable>(_ type: T.Type) {
            let descriptor = FetchDescriptor<T>()
            guard let all = try? modelContext.fetch(descriptor) else { return }
            for r in all {
                if r.uploadStatus == UploadStatus.uploaded.rawValue {
                    uploaded += 1
                } else if r.uploadStatus == UploadStatus.pending.rawValue || r.uploadStatus == UploadStatus.failed.rawValue {
                    pending += 1
                }
            }
        }

        count(LocationRecord.self)
        count(ActivityRecord.self)
        count(PedometerRecord.self)
        count(AltimeterRecord.self)
        count(BatteryRecord.self)
        count(ConnectivityRecord.self)
        count(VisitRecord.self)
        count(CompassRecord.self)
        count(ThermalRecord.self)
        count(NoiseRecord.self)
        count(NowPlayingRecord.self)
        count(ProximityRecord.self)
        count(ScreenLockRecord.self)
        count(AppearanceRecord.self)
        count(CellularRecord.self)
        count(MemoryRecord.self)
        count(PhotoActivityRecord.self)
        count(CalendarRecord.self)
        count(AppLifecycleRecord.self)
        count(GeofenceRecord.self)

        totalPendingCount = pending
        totalUploadedCount = uploaded
    }

    /// Uploads all pending records across all collector types to Supabase.
    @MainActor
    func uploadPendingRecords(modelContext: ModelContext) async {
        guard settings.isConfigured else {
            logger.warning("Supabase not configured, skipping upload")
            return
        }

        guard !isUploading else {
            logger.info("Upload already in progress, skipping")
            return
        }

        isUploading = true
        defer {
            isUploading = false
            refreshCounts(modelContext: modelContext)
        }

        await uploadBatch(fetchPending(LocationRecord.self, from: modelContext), table: LocationRecord.supabaseTable, modelContext: modelContext)
        await uploadBatch(fetchPending(ActivityRecord.self, from: modelContext), table: ActivityRecord.supabaseTable, modelContext: modelContext)
        await uploadBatch(fetchPending(PedometerRecord.self, from: modelContext), table: PedometerRecord.supabaseTable, modelContext: modelContext)
        await uploadBatch(fetchPending(AltimeterRecord.self, from: modelContext), table: AltimeterRecord.supabaseTable, modelContext: modelContext)
        await uploadBatch(fetchPending(BatteryRecord.self, from: modelContext), table: BatteryRecord.supabaseTable, modelContext: modelContext)
        await uploadBatch(fetchPending(ConnectivityRecord.self, from: modelContext), table: ConnectivityRecord.supabaseTable, modelContext: modelContext)
        await uploadBatch(fetchPending(VisitRecord.self, from: modelContext), table: VisitRecord.supabaseTable, modelContext: modelContext)
        await uploadBatch(fetchPending(CompassRecord.self, from: modelContext), table: CompassRecord.supabaseTable, modelContext: modelContext)
        await uploadBatch(fetchPending(ThermalRecord.self, from: modelContext), table: ThermalRecord.supabaseTable, modelContext: modelContext)
        await uploadBatch(fetchPending(NoiseRecord.self, from: modelContext), table: NoiseRecord.supabaseTable, modelContext: modelContext)
        await uploadBatch(fetchPending(NowPlayingRecord.self, from: modelContext), table: NowPlayingRecord.supabaseTable, modelContext: modelContext)
        await uploadBatch(fetchPending(ProximityRecord.self, from: modelContext), table: ProximityRecord.supabaseTable, modelContext: modelContext)
        await uploadBatch(fetchPending(ScreenLockRecord.self, from: modelContext), table: ScreenLockRecord.supabaseTable, modelContext: modelContext)
        await uploadBatch(fetchPending(AppearanceRecord.self, from: modelContext), table: AppearanceRecord.supabaseTable, modelContext: modelContext)
        await uploadBatch(fetchPending(CellularRecord.self, from: modelContext), table: CellularRecord.supabaseTable, modelContext: modelContext)
        await uploadBatch(fetchPending(MemoryRecord.self, from: modelContext), table: MemoryRecord.supabaseTable, modelContext: modelContext)
        await uploadBatch(fetchPending(PhotoActivityRecord.self, from: modelContext), table: PhotoActivityRecord.supabaseTable, modelContext: modelContext)
        await uploadBatch(fetchPending(CalendarRecord.self, from: modelContext), table: CalendarRecord.supabaseTable, modelContext: modelContext)
        await uploadBatch(fetchPending(AppLifecycleRecord.self, from: modelContext), table: AppLifecycleRecord.supabaseTable, modelContext: modelContext)
        await uploadBatch(fetchPending(GeofenceRecord.self, from: modelContext), table: GeofenceRecord.supabaseTable, modelContext: modelContext)
        // HealthRecord upload disabled — HealthKit entitlement requires Apple approval
        // await uploadBatch(fetchPending(HealthRecord.self, from: modelContext), table: HealthRecord.supabaseTable, modelContext: modelContext)
    }

    // MARK: - Private

    private func fetchPending<T: PersistentModel & Uploadable>(_ type: T.Type, from modelContext: ModelContext) -> [T] {
        let descriptor = FetchDescriptor<T>()
        guard let all = try? modelContext.fetch(descriptor) else { return [] }
        return all.filter {
            ($0.uploadStatus == UploadStatus.pending.rawValue || $0.uploadStatus == UploadStatus.failed.rawValue)
            && $0.uploadAttempts < 5
        }
    }

    private func uploadBatch<T: PersistentModel & Uploadable>(_ records: [T], table: String, modelContext: ModelContext) async {
        guard !records.isEmpty else { return }

        logger.info("Uploading \(records.count) \(table) records")

        for record in records {
            record.uploadStatus = UploadStatus.uploading.rawValue
        }
        try? modelContext.save()

        do {
            let request = try buildRequest(records: records, table: table)
            let (_, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw UploadError.invalidResponse
            }

            if (200...299).contains(httpResponse.statusCode) {
                for record in records {
                    record.uploadStatus = UploadStatus.uploaded.rawValue
                }
                settings.lastUploadDate = Date()
                lastError = nil
                logger.info("Successfully uploaded \(records.count) \(table) records")
            } else {
                throw UploadError.httpError(httpResponse.statusCode)
            }

            try modelContext.save()
        } catch {
            logger.error("Upload failed for \(table): \(error.localizedDescription)")
            lastError = error.localizedDescription

            for record in records {
                record.uploadStatus = UploadStatus.failed.rawValue
                record.uploadAttempts += 1
                record.lastUploadAttempt = Date()
            }
            try? modelContext.save()
        }
    }

    private func buildRequest<T: Uploadable>(records: [T], table: String) throws -> URLRequest {
        guard let url = URL(string: "\(settings.supabaseURL)/rest/v1/\(table)") else {
            throw UploadError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(settings.supabaseAPIKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(settings.supabaseAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal,resolution=ignore-duplicates", forHTTPHeaderField: "Prefer")

        let payload = records.map { $0.toSupabaseJSON() }
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        return request
    }
}

enum UploadError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid Supabase URL"
        case .invalidResponse: return "Invalid server response"
        case .httpError(let code): return "Server error (HTTP \(code))"
        }
    }
}
