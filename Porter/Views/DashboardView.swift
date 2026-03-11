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
                Section("Collectors") {
                    ForEach(collectorManager.collectors, id: \.id) { collector in
                        CollectorRow(collector: collector)
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
            .navigationTitle("Porter")
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
                    Menu {
                        Button {
                            enableAll()
                        } label: {
                            Label("Enable All", systemImage: "bolt.fill")
                        }

                        Button(role: .destructive) {
                            disableAll()
                        } label: {
                            Label("Disable All", systemImage: "bolt.slash")
                        }

                        Divider()

                        NavigationLink {
                            SettingsView(
                                uploadService: uploadService,
                                settings: settings
                            )
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }

    private func enableAll() {
        for collector in collectorManager.collectors {
            let key = "collector_\(collector.id)_enabled"
            UserDefaults.standard.set(true, forKey: key)
            if collector.permissionStatus.isGranted {
                collector.start()
            }
        }
    }

    private func disableAll() {
        for collector in collectorManager.collectors {
            let key = "collector_\(collector.id)_enabled"
            UserDefaults.standard.set(false, forKey: key)
            collector.stop()
        }
    }
}

/// A single row displaying a collector's name, status, and toggle.
private struct CollectorRow: View {
    let collector: any DataCollector

    private var enabledKey: String { "collector_\(collector.id)_enabled" }

    private var isEnabled: Binding<Bool> {
        Binding(
            get: { UserDefaults.standard.bool(forKey: enabledKey) },
            set: { newValue in
                UserDefaults.standard.set(newValue, forKey: enabledKey)
                if newValue {
                    if collector.permissionStatus == .notDetermined {
                        collector.requestPermission()
                    }
                    if collector.permissionStatus.isGranted {
                        collector.start()
                    }
                } else {
                    collector.stop()
                }
            }
        )
    }

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
            }

            Toggle("", isOn: isEnabled)
                .labelsHidden()
        }
    }
}
