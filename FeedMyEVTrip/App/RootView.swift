import SwiftData
import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            SearchView()
                .tabItem {
                    Label("Find", systemImage: "map")
                }

            SavedStopsView()
                .tabItem {
                    Label("Saved", systemImage: "bookmark")
                }

            FoodPreferencesView()
                .tabItem {
                    Label("Preferences", systemImage: "slider.horizontal.3")
                }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: SavedStop.self, inMemory: true)
}
