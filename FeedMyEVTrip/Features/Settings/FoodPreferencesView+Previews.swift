import SwiftUI

#Preview("Food preferences") {
    FoodPreferencesView()
        .defaultAppStorage(previewPreferencesStore())
}

private func previewPreferencesStore() -> UserDefaults {
    let store = UserDefaults(suiteName: "FoodPreferencesPreview")!
    store.set(10, forKey: FoodPreferenceKeys.maximumWalkingMinutes)
    store.set(true, forKey: FoodPreferenceKeys.includesRestaurants)
    store.set(true, forKey: FoodPreferenceKeys.includesCafes)
    store.set(false, forKey: FoodPreferenceKeys.includesBakeries)
    store.set(true, forKey: ChargerConnector.ccs.storageKey)
    store.set(true, forKey: ChargerConnector.nacs.storageKey)
    store.set(false, forKey: ChargerConnector.chademo.storageKey)
    return store
}
