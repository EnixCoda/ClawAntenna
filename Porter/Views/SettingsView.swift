import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allRecords: [LocationRecord]

    @Bindable var settings: AppSettings

    @State private var apiKeyInput: String = ""
    @State private var showClearConfirmation = false

    var body: some View {
        Form {
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
                    Label("Not configured", systemImage: "exclamationmark.circle")
                        .foregroundStyle(.orange)
                }
            }

            Section("Data") {
                LabeledContent("Total Records", value: "\(allRecords.count)")
                LabeledContent("Uploaded", value: "\(allRecords.filter { $0.status == .uploaded }.count)")
                LabeledContent("Pending", value: "\(allRecords.filter { $0.status == .pending || $0.status == .failed }.count)")

                Button("Clear Uploaded Records", role: .destructive) {
                    showClearConfirmation = true
                }
                .disabled(allRecords.filter { $0.status == .uploaded }.count == 0)
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
