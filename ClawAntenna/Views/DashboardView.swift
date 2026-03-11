import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LocationRecord.recordedAt, order: .reverse) private var allRecords: [LocationRecord]

    var collectorManager: CollectorManager
    var uploadService: UploadService
    var settings: AppSettings

    private var pendingCount: Int {
        allRecords.filter { $0.status == .pending || $0.status == .failed }.count
    }

    var body: some View {
        NavigationStack {
            List {
                if !settings.isConfigured {
                    Section {
                        NavigationLink {
                            SettingsView(
                                uploadService: uploadService,
                                settings: settings
                            )
                        } label: {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Data connection not configured")
                                        .font(.subheadline.weight(.medium))
                                    Text("Set up Supabase to upload collected data.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }

                Section("Collectors") {
                    ForEach(collectorManager.collectors, id: \.id) { collector in
                        NavigationLink {
                            CollectorDetailView(collector: collector)
                        } label: {
                            CollectorRow(collector: collector)
                        }
                    }
                }

                Section {
                    HStack {
                        Label(
                            "\(collectorManager.activeCount) of \(collectorManager.availableCount) active",
                            systemImage: "antenna.radiowaves.left.and.right"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("ClawAntenna")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if pendingCount > 0 {
                        Button {
                            Task {
                                await uploadService.uploadPendingRecords(modelContext: modelContext)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                if uploadService.isUploading {
                                    ProgressView()
                                        .controlSize(.mini)
                                } else {
                                    Image(systemName: "arrow.up.circle")
                                }
                                Text("\(pendingCount)")
                                    .font(.caption.weight(.medium))
                            }
                        }
                        .disabled(!settings.isConfigured || uploadService.isUploading)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView(
                            uploadService: uploadService,
                            settings: settings
                        )
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
        }
    }


}

/// A single row displaying a collector's name and status.
private struct CollectorRow: View {
    let collector: any DataCollector

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: collector.icon)
                .font(.title2)
                .foregroundStyle(collector.isRunning ? .green : .secondary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(collector.name)
                    .font(.body.weight(.medium))

                Text(collector.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if collector.permissionStatus == .denied {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .font(.caption)
            } else if collector.permissionStatus == .limited {
                Image(systemName: "exclamationmark.circle")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }

            if collector.isRunning {
                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.green)
            }
        }
    }
}
