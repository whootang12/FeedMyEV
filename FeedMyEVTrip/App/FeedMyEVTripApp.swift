import SwiftUI
import SwiftData

@main struct FeedMyEVTripApp: App {
    init() {
        RouteWindowSettings.preserveLegacyMilesWindow()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: SavedStore.modelTypes)
    }
}
