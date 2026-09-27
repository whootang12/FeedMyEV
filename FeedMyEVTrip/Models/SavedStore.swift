import SwiftData

enum SavedStore {
    static let modelTypes: [any PersistentModel.Type] = [
        SavedStop.self,
        SavedRestaurantChain.self,
        SavedRestaurantLocation.self
    ]

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        try ModelContainer(
            for: SavedStop.self,
            SavedRestaurantChain.self,
            SavedRestaurantLocation.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: inMemory)
        )
    }
}
