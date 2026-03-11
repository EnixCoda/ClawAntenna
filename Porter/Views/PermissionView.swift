import SwiftUI
import CoreLocation

struct PermissionView: View {
    var locationManager: LocationManager
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Branding
            VStack(spacing: 8) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 56))
                    .foregroundStyle(.tint)

                Text("Porter")
                    .font(.largeTitle.bold())

                Text("Silent data collection agent for your iPhone")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Permission ask
            VStack(spacing: 12) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)

                Text("Location Access")
                    .font(.title3.bold())

                Text("Porter collects your location in the background and reports it to your configured endpoint. This requires \"Always\" location permission.")
                    .font(.callout)
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
