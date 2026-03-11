import SwiftUI

/// Detail page for a single collector with permission guidance and enable toggle.
struct CollectorDetailView: View {
    let collector: any DataCollector

    private var enabledKey: String { "collector_\(collector.id)_enabled" }

    private var isEnabled: Binding<Bool> {
        Binding(
            get: { UserDefaults.standard.bool(forKey: enabledKey) },
            set: { newValue in
                UserDefaults.standard.set(newValue, forKey: enabledKey)
                if newValue {
                    collector.start()
                } else {
                    collector.stop()
                }
            }
        )
    }

    var body: some View {
        List {
            // MARK: - Hero
            Section {
                VStack(spacing: 12) {
                    Image(systemName: collector.icon)
                        .font(.system(size: 44))
                        .foregroundStyle(collector.isRunning ? .green : .secondary)

                    Text(collector.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            // MARK: - Toggle
            Section {
                Toggle(isOn: isEnabled) {
                    Label(
                        collector.isRunning ? "Running" : "Stopped",
                        systemImage: collector.isRunning ? "bolt.fill" : "bolt.slash"
                    )
                }
            }

            // MARK: - Permission
            Section("Permission") {
                PermissionStatusRow(collector: collector)
            }

            // MARK: - Status
            if collector.isRunning || collector.lastError != nil {
                Section("Status") {
                    if collector.isRunning {
                        Label("Collecting data", systemImage: "antenna.radiowaves.left.and.right")
                            .foregroundStyle(.green)
                    }
                    if let error = collector.lastError {
                        Label(error, systemImage: "xmark.circle")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle(collector.name)
    }
}

/// Shows permission status with step-by-step guidance and action buttons.
private struct PermissionStatusRow: View {
    let collector: any DataCollector

    var body: some View {
        switch collector.permissionStatus {
        case .notRequired:
            Label("No permission required", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)

        case .notDetermined:
            Label("Not yet requested", systemImage: "questionmark.circle")
                .foregroundStyle(.secondary)

            Button {
                collector.requestPermission()
            } label: {
                Text("Grant Permission")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

        case .limited:
            Label("\"When In Use\" granted", systemImage: "checkmark.circle")
                .foregroundStyle(.orange)

            Text("Background collection requires \"Always\" permission. Tap below to upgrade, or go to Settings → ClawAntenna → Location → Always.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                collector.requestPermission()
            } label: {
                Text("Upgrade to Always Allow")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }

        case .authorized:
            Label("Full access granted", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)

        case .denied:
            Label("Permission denied", systemImage: "xmark.circle")
                .foregroundStyle(.red)

            Text("This collector cannot run without permission. Please enable it in Settings → ClawAntenna.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)

        case .restricted:
            Label("Restricted by device policy", systemImage: "lock.fill")
                .foregroundStyle(.red)

            Text("This feature is restricted on this device (e.g. parental controls).")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
