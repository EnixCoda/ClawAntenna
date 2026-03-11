import Foundation
import SwiftData
import os

@Observable
final class UploadService {
    private let logger = Logger(subsystem: "co.enix.Porter", category: "Upload")
    private let settings: AppSettings
    private let session = URLSession.shared

    var isUploading = false
    var lastError: String?

    init(settings: AppSettings) {
        self.settings = settings
    }

    /// Uploads all pending records to Supabase. Marks them as uploaded on success.
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
        defer { isUploading = false }

        do {
            let pending = try fetchPendingRecords(modelContext: modelContext)
            guard !pending.isEmpty else {
                logger.info("No pending records to upload")
                return
            }

            logger.info("Uploading \(pending.count) pending records")

            // Mark as uploading
            for record in pending {
                record.status = .uploading
            }
            try modelContext.save()

            // Build request
            let request = try buildRequest(records: pending)
            let (_, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw UploadError.invalidResponse
            }

            if (200...299).contains(httpResponse.statusCode) {
                // Success — mark as uploaded
                for record in pending {
                    record.status = .uploaded
                }
                settings.lastUploadDate = Date()
                lastError = nil
                logger.info("Successfully uploaded \(pending.count) records")
            } else {
                throw UploadError.httpError(httpResponse.statusCode)
            }

            try modelContext.save()
        } catch {
            logger.error("Upload failed: \(error.localizedDescription)")
            lastError = error.localizedDescription

            // Mark failed records for retry
            if let pending = try? fetchUploadingRecords(modelContext: modelContext) {
                for record in pending {
                    record.status = .failed
                    record.uploadAttempts += 1
                    record.lastUploadAttempt = Date()
                }
                try? modelContext.save()
            }
        }
    }

    // MARK: - Private

    private func fetchPendingRecords(modelContext: ModelContext) throws -> [LocationRecord] {
        let pendingValue = UploadStatus.pending.rawValue
        let failedValue = UploadStatus.failed.rawValue
        let maxAttempts = 5

        let descriptor = FetchDescriptor<LocationRecord>(
            predicate: #Predicate<LocationRecord> {
                ($0.uploadStatus == pendingValue || $0.uploadStatus == failedValue)
                && $0.uploadAttempts < maxAttempts
            },
            sortBy: [SortDescriptor(\.recordedAt)]
        )

        return try modelContext.fetch(descriptor)
    }

    private func fetchUploadingRecords(modelContext: ModelContext) throws -> [LocationRecord] {
        let uploadingValue = UploadStatus.uploading.rawValue
        let descriptor = FetchDescriptor<LocationRecord>(
            predicate: #Predicate<LocationRecord> {
                $0.uploadStatus == uploadingValue
            }
        )
        return try modelContext.fetch(descriptor)
    }

    private func buildRequest(records: [LocationRecord]) throws -> URLRequest {
        guard let url = URL(string: "\(settings.supabaseURL)/rest/v1/locations") else {
            throw UploadError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(settings.supabaseAPIKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(settings.supabaseAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.setValue("ignore-duplicates", forHTTPHeaderField: "Prefer")

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
