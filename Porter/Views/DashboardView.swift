import SwiftUI
import SwiftData
import CoreLocation

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LocationRecord.recordedAt, order: .reverse) private var allRecords: [LocationRecord]

    var locationManager: LocationManager
    var uploadService: UploadService
    var settings: AppSettings

    private var pendingCount: Int {
        allRecords.filter { $0.status == .pending || $0.status == .failed }.count
    }
    private var uploadedCount: Int {
        allRecords.filter { $0.status == .uploaded }.count
    }
    private var failedCount: Int {
        allRecords.filter { $0.status == .failed && $0.uploadAttempts >= 5 }.count
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Tracking") {
                    HStack {
                        Label(
                            locationManager.isMonitoring ? "Monitoring" : "Stopped",
                            systemImage: locationManager.isMonitoring ? "location.fill" : "location.slash"
                        )
                        .foregroundStyle(locationManager.isMonitoring ? .green : .secondary)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { settings.isTrackingEnabled },
                            set: { newValue in
                                settings.isTrackingEnabled = newValue
                                if newValue {
                                    locationManager.startMonitoring()
                                } else {
                                    locationManager.stopMonitoring()
                                }
                            }
                        ))
                    }

                    if !locationManager.hasAlwaysPermission {
                        HStack {
                            Label("Permission: \(locationManager.permissionDescription)", systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                            Spacer()
                            Button("Grant") {
                                locationManager.requestPermission()
                            }
                            .buttonStyle(.bordered)
                            .tint(.orange)
                        }
                    }
                }

                Section("Last Location") {
                    if let loc = locationManager.currentLocation {
                        LabeledContent("Latitude", value: String(format: "%.6f", loc.coordinate.latitude))
                        LabeledContent("Longitude", value: String(format: "%.6f", loc.coordinate.longitude))
                        LabeledContent("Altitude", value: String(format: "%.1f m", loc.altitude))
                        LabeledContent("Accuracy", value: String(format: "%.1f m", loc.horizontalAccuracy))
                        LabeledContent("Time", value: loc.timestamp.formatted(.dateTime))
                    } else {
                        Text("Waiting for first location update...")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Upload Queue") {
                    LabeledContent("Total Records", value: "\(allRecords.count)")
                    LabeledContent("Pending", value: "\(pendingCount)")
                    LabeledContent("Uploaded", value: "\(uploadedCount)")
                    if failedCount > 0 {
                        LabeledContent("Failed (max retries)", value: "\(failedCount)")
                            .foregroundStyle(.red)
                    }

                    if let lastUpload = settings.lastUploadDate {
                        LabeledContent("Last Upload", value: lastUpload.formatted(.relative(presentation: .named)))
                    }

                    if uploadService.isUploading {
                        HStack {
                            ProgressView()
                                .padding(.trailing, 4)
                            Text("Uploading...")
                                .foregroundStyle(.secondary)
                        }
                    }

                    if !settings.isConfigured {
                        Label("Supabase not configured", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }

                    if let error = uploadService.lastError {
                        Label(error, systemImage: "xmark.circle")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }

                    Button {
                        Task {
                            await uploadService.uploadPendingRecords(modelContext: modelContext)
                        }
                    } label: {
                        Label("Upload Now", systemImage: "arrow.up.circle")
                    }
                    .disabled(!settings.isConfigured || uploadService.isUploading || pendingCount == 0)
                }
            }
            .navigationTitle("Porter")
            .toolbar {
                NavigationLink {
                    SettingsView(settings: settings)
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
    }
}
