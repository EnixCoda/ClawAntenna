import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allRecords: [LocationRecord]

    var uploadService: UploadService
    @Bindable var settings: AppSettings

    @State private var apiKeyInput: String = ""
    @State private var showClearConfirmation = false

    private var pendingCount: Int {
        allRecords.filter { $0.status == .pending || $0.status == .failed }.count
    }
    private var uploadedCount: Int {
        allRecords.filter { $0.status == .uploaded }.count
    }

    var body: some View {
        List {
            Section("Supabase Connection") {
                TextField("Project URL", text: $settings.supabaseURL)
                    .textContentType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .overlay(alignment: .trailing) {
                        if !settings.supabaseURL.isEmpty {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }

                SecureField("Service Role Key", text: $apiKeyInput)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit {
                        settings.supabaseAPIKey = apiKeyInput
                    }
                    .onChange(of: apiKeyInput) {
                        settings.supabaseAPIKey = apiKeyInput
                    }
                    .overlay(alignment: .trailing) {
                        if !settings.supabaseAPIKey.isEmpty {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }

                if settings.isConfigured {
                    Label("Connected", systemImage: "checkmark.circle")
                        .foregroundStyle(.green)
                } else {
                    Label("Not configured", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }

            Section("Upload Queue") {
                HStack {
                    Text("\(allRecords.count) records")
                    Spacer()
                    Group {
                        Text("\(pendingCount) pending")
                            .foregroundStyle(pendingCount > 0 ? .primary : .secondary)
                        Text("·")
                        Text("\(uploadedCount) uploaded")
                            .foregroundStyle(.green)
                    }
                    .font(.caption)
                }

                if uploadService.isUploading {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.trailing, 4)
                        Text("Uploading...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if let error = uploadService.lastError {
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

                Button("Clear Uploaded Records", role: .destructive) {
                    showClearConfirmation = true
                }
                .disabled(uploadedCount == 0)
            }

            Section("About") {
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–")
                LabeledContent("Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–")

                Link(destination: URL(string: "https://github.com/EnixCoda/ClawAntenna")!) {
                    HStack {
                        Label("GitHub", systemImage: "star")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            apiKeyInput = settings.supabaseAPIKey
        }
        .confirmationDialog("Clear Records", isPresented: $showClearConfirmation) {
            Button("Clear Uploaded Records", role: .destructive) {
                clearUploadedRecords()
            }
        } message: {
            Text("This will delete all successfully uploaded records from this device.")
        }
    }

    private func clearUploadedRecords() {
        let uploaded = allRecords.filter { $0.status == .uploaded }
        for record in uploaded {
            modelContext.delete(record)
        }
        try? modelContext.save()
    }
}
