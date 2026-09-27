import SwiftData
import SwiftUI

struct SavedRestaurantLocationDetailsView: View {
    @Bindable var location: SavedRestaurantLocation

    var body: some View {
        List {
            Section {
                Label(location.name, systemImage: "fork.knife")
                    .font(.title2.weight(.semibold))

                if !location.address.isEmpty {
                    Label(location.address, systemImage: "mappin.and.ellipse")
                        .textSelection(.enabled)
                }

                LabeledContent("Saved", value: location.savedAt.formatted(date: .abbreviated, time: .omitted))
            }

            Section("Notes") {
                TextField("Notes", text: $location.note, axis: .vertical)
                    .lineLimit(3...8)
            }
        }
        .navigationTitle("Saved Location")
        .navigationBarTitleDisplayMode(.inline)
    }
}
