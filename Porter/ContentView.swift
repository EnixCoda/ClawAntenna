import SwiftUI

struct ContentView: View {
    var locationManager: LocationManager
    var uploadService: UploadService
    var settings: AppSettings

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            DashboardView(
                locationManager: locationManager,
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
