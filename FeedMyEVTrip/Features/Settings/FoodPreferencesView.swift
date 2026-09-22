import SwiftUI

struct FoodPreferencesView: View {
    @AppStorage(FoodPreferenceKeys.maximumWalkingMinutes)
    private var maximumWalkingMinutes = 15

    @AppStorage(FoodPreferenceKeys.includesRestaurants)
    private var includesRestaurants = true

    @AppStorage(FoodPreferenceKeys.includesCafes)
    private var includesCafes = true

    @AppStorage(FoodPreferenceKeys.includesBakeries)
    private var includesBakeries = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Maximum walk", selection: $maximumWalkingMinutes) {
                        Text("5 minutes").tag(5)
                        Text("10 minutes").tag(10)
                        Text("15 minutes").tag(15)
                        Text("20 minutes").tag(20)
                    }
                } header: {
                    Text("Walking distance")
                } footer: {
                    Text("Walking times are initial estimates based on straight-line distance.")
                }

                Section {
                    Toggle("Restaurants", isOn: $includesRestaurants)
                        .disabled(!includesCafes && !includesBakeries)
                    Toggle("Cafés", isOn: $includesCafes)
                        .disabled(!includesRestaurants && !includesBakeries)
                    Toggle("Bakeries", isOn: $includesBakeries)
                        .disabled(!includesRestaurants && !includesCafes)
                } header: {
                    Text("Include")
                } footer: {
                    Text("At least one type must remain selected.")
                }
            }
            .navigationTitle("Food Preferences")
        }
    }
}
