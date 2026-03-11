import SwiftUI

struct ContentView: View {
    var locationManager: LocationManager
    var collectorManager: CollectorManager
    @Bindable var uploadService: UploadService
    @Bindable var settings: AppSettings

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            DashboardView(
                collectorManager: collectorManager,
                uploadService: uploadService,
                settings: settings
            )
        } else {
            PermissionView(locationManager: locationManager) {
                hasCompletedOnboarding = true
            }
        }
    }
}
