import SwiftUI
import SwiftData
import CoreLocation

@main
struct ClawAntennaApp: App {
    let modelContainer: ModelContainer
    @State private var settings = AppSettings()
    @State private var locationManager = LocationManager()
    @State private var collectorManager: CollectorManager?
    @State private var uploadService: UploadService?
    @State private var isReady = false

    init() {
        do {
            modelContainer = try ModelContainer(for:
                LocationRecord.self,
                ActivityRecord.self,
                PedometerRecord.self,
                AltimeterRecord.self,
                BatteryRecord.self,
                ConnectivityRecord.self,
                HealthRecord.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isReady, let uploadService, let collectorManager {
                    ContentView(
                        collectorManager: collectorManager,
                        uploadService: uploadService,
                        settings: settings
                    )
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 40))
                            .foregroundStyle(.tint)
                        Text("ClawAntenna")
                            .font(.title2.bold())
                        ProgressView()
                    }
                }
            }
            .modelContainer(modelContainer)
            .onAppear {
                locationManager.setup()
                let service = UploadService(settings: settings)
                uploadService = service
                let manager = CollectorManager(locationManager: locationManager)
                collectorManager = manager
                setupLocationHandler(uploadService: service)
                locationManager.onAuthorizationChange = { [manager] in
                    manager.location.handleAuthorizationChange()
                }
                // Migrate legacy tracking toggle to collector system
                if settings.isTrackingEnabled {
                    UserDefaults.standard.set(true, forKey: "collector_location_enabled")
                }
                manager.startEnabled(settings: settings)
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
