import MapKit
import SwiftData
import SwiftUI

// MARK: - Saved stops

struct SavedStopsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedStop.savedAt, order: .reverse) private var savedStops: [SavedStop]

    var body: some View {
        NavigationStack {
            Group {
                if savedStops.isEmpty {
                    ContentUnavailableView(
                        "No Saved Stops",
                        systemImage: "bookmark",
                        description: Text("Choose a charger on the map, then save it for later.")
                    )
                } else {
                    List {
                        ForEach(savedStops) { stop in
                            stopRow(stop)
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Saved Stops")
        }
    }

    private func stopRow(_ stop: SavedStop) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Label(stop.chargerName, systemImage: "bolt.fill")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Text(stop.savedAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(stop.address)
                .font(.caption)
                .foregroundStyle(.secondary)

            if !stop.nearbyFoodNames.isEmpty {
                Label(stop.nearbyFoodNames.joined(separator: "  •  "), systemImage: "fork.knife")
                    .font(.caption)
                    .lineLimit(2)
            }

            Button {
                openDirections(to: stop)
            } label: {
                Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond")
            }
            .buttonStyle(.bordered)
            .tint(.green)
        }
        .padding(.vertical, 6)
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(savedStops[index])
        }
    }

    private func openDirections(to stop: SavedStop) {
        let location = CLLocation(latitude: stop.latitude, longitude: stop.longitude)
        let item = MKMapItem(location: location, address: nil)
        item.name = stop.chargerName
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}
