import SwiftUI
import CoreLocation

struct PermissionView: View {
    var locationManager: LocationManager
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "location.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            VStack(spacing: 12) {
                Text("Location Access")
                    .font(.title.bold())

                Text("Porter collects your location in the background and reports it to your configured endpoint. This requires \"Always\" location permission.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: 16) {
                switch locationManager.authorizationStatus {
                case .notDetermined:
                    Button {
                        locationManager.requestPermission()
                    } label: {
                        Text("Enable Location")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                case .authorizedWhenInUse:
                    Label("\"When In Use\" granted", systemImage: "checkmark.circle")
                        .foregroundStyle(.green)

                    Button {
                        locationManager.requestPermission()
                    } label: {
                        Text("Upgrade to Always Allow")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Text("Background tracking requires \"Always\" permission. You can also change this in Settings → Porter → Location.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                case .authorizedAlways:
                    Label("\"Always\" permission granted", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.headline)

                case .denied, .restricted:
                    Label("Location access denied", systemImage: "xmark.circle")
                        .foregroundStyle(.red)

                    Text("Please open Settings → Porter → Location and select \"Always\".")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                @unknown default:
                    EmptyView()
                }
            }
            .padding(.horizontal)

            Spacer()

            if locationManager.hasAnyPermission {
                Button {
                    onComplete()
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
            }
        }
        .padding()
    }
}
