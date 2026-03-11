import SwiftUI
import SwiftData
import CoreLocation

@main
struct PorterApp: App {
    let modelContainer: ModelContainer
    @State private var settings = AppSettings()
    @State private var locationManager = LocationManager()
    @State private var uploadService: UploadService?
    @State private var isReady = false

    init() {
        do {
            modelContainer = try ModelContainer(for: LocationRecord.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isReady, let uploadService {
                    ContentView(
                        locationManager: locationManager,
                        uploadService: uploadService,
                        settings: settings
                    )
                } else {
                    ProgressView("Starting...")
                }
            }
            .modelContainer(modelContainer)
            .onAppear {
                locationManager.setup()
                let service = UploadService(settings: settings)
                uploadService = service
                setupLocationHandler(uploadService: service)
                if settings.isTrackingEnabled && locationManager.hasAnyPermission {
                    locationManager.startMonitoring()
                }
                isReady = true
            }
        }
    }

    private func setupLocationHandler(uploadService: UploadService) {
        locationManager.onLocationUpdate = { location in
            Task { @MainActor in
                let context = ModelContext(self.modelContainer)
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

                if self.settings.isConfigured {
                    let uploadContext = ModelContext(self.modelContainer)
                    await uploadService.uploadPendingRecords(modelContext: uploadContext)
                }
            }
        }
    }
}
