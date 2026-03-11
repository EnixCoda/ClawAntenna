import SwiftUI
import SwiftData
import CoreLocation

@main
struct PorterApp: App {
    @State private var settings = AppSettings()
    @State private var locationManager = LocationManager()
    @State private var uploadService: UploadService

    let modelContainer: ModelContainer

    init() {
        let container = try! ModelContainer(for: LocationRecord.self)
        self.modelContainer = container

        let appSettings = AppSettings()
        self._settings = State(initialValue: appSettings)
        self._uploadService = State(initialValue: UploadService(settings: appSettings))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                locationManager: locationManager,
                uploadService: uploadService,
                settings: settings
            )
            .modelContainer(modelContainer)
            .onAppear {
                setupLocationHandler()
                if settings.isTrackingEnabled && locationManager.hasAnyPermission {
                    locationManager.startMonitoring()
                }
            }
        }
    }

    private func setupLocationHandler() {
        locationManager.onLocationUpdate = { [settings] location in
            let context = ModelContext(modelContainer)
            let record = LocationRecord(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                altitude: location.altitude,
                horizontalAccuracy: location.horizontalAccuracy,
                speed: location.speed,
                recordedAt: location.timestamp
            )
            context.insert(record)
            try? context.save()

            // Trigger upload in background
            if settings.isConfigured {
                Task { @MainActor in
                    let uploadContext = ModelContext(modelContainer)
                    await uploadService.uploadPendingRecords(modelContext: uploadContext)
                }
            }
        }
    }
}
