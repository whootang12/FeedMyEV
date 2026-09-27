import SwiftUI
import SwiftData

@main struct FeedMyEVTripApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: SavedStore.modelTypes)
    }
}
