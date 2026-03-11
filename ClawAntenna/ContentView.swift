import SwiftUI

struct ContentView: View {
    var collectorManager: CollectorManager
    @Bindable var uploadService: UploadService
    @Bindable var settings: AppSettings

    var body: some View {
        DashboardView(
            collectorManager: collectorManager,
            uploadService: uploadService,
            settings: settings
        )
    }
}
