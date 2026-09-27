import MapKit
import SwiftUI

private struct SavedFoodSelection: Identifiable {
    let id = UUID()
    let food: MKMapItem
    let distanceAndWalk: String
}

private struct SavedFoodRow: Identifiable {
    let id: String
    let name: String
    let place: SavedNearbyFood?
}

struct SavedStopDetailsView: View {
    @Bindable var stop: SavedStop
    @StateObject private var searchService = MapSearchService()
    @State private var selectedFood: SavedFoodSelection?
    @State private var loadingFoodName: String?
    @State private var foodLookupMessage: String?
    @State private var lookupTask: Task<Void, Never>?

    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude)
    }

    private var mapItem: MKMapItem {
        let item = MKMapItem(
            location: CLLocation(latitude: stop.latitude, longitude: stop.longitude),
            address: nil
        )
        item.name = stop.chargerName
        return item
    }

    var body: some View {
        List {
            Section {
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: coordinate,
                    latitudinalMeters: 1_500,
                    longitudinalMeters: 1_500
                )), interactionModes: []) {
                    Marker(stop.chargerName, systemImage: "bolt.fill", coordinate: coordinate)
                        .tint(.green)
                }
                .frame(height: 220)
                .listRowInsets(EdgeInsets())
                .accessibilityLabel("Map showing \(stop.chargerName)")

                Label(stop.chargerName, systemImage: "bolt.fill")
                    .font(.title2.weight(.semibold))

                if !stop.address.isEmpty {
                    Label(stop.address, systemImage: "mappin.and.ellipse")
                        .textSelection(.enabled)
                }

                LabeledContent("Saved", value: stop.savedAt.formatted(date: .abbreviated, time: .omitted))
            }

            Section("Notes") {
                TextField("Notes", text: $stop.note, axis: .vertical)
                    .lineLimit(3...8)
            }

            Section {
                Button {
                    mapItem.openInMaps(launchOptions: [
                        MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
                    ])
                } label: {
                    Label("Driving directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                }

                Button {
                    mapItem.openInMaps()
                } label: {
                    Label("Open in Apple Maps", systemImage: "map")
                }
            }
            .tint(.green)

            Section {
                if foodRows.isEmpty {
                    Text("No nearby food was saved with this stop.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(foodRows) { row in
                        Button {
                            openFood(row)
                        } label: {
                            HStack {
                                Label(row.name, systemImage: "fork.knife")
                                Spacer()
                                if loadingFoodName == row.name {
                                    ProgressView()
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("View \(row.name)")
                    }
                }
            } header: {
                Text("Nearby food")
            } footer: {
                if let foodLookupMessage {
                    Text(foodLookupMessage)
                } else {
                    Text("Food options recorded when you saved this stop.")
                }
            }
        }
        .navigationTitle("Saved Stop")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedFood) { selection in
            FoodDetailsView(
                food: selection.food,
                charger: mapItem,
                distanceAndWalk: selection.distanceAndWalk
            )
            .presentationDetents([.medium, .large])
        }
        .onDisappear {
            lookupTask?.cancel()
        }
    }

    private var foodRows: [SavedFoodRow] {
        let places = stop.nearbyFoodPlaces
        if !places.isEmpty {
            return places.map { SavedFoodRow(id: $0.id, name: $0.name, place: $0) }
        }
        return stop.nearbyFoodNames.enumerated().map { index, name in
            SavedFoodRow(id: "\(index):\(name)", name: name, place: nil)
        }
    }

    private func openFood(_ row: SavedFoodRow) {
        if let place = row.place {
            selectedFood = selection(for: place.mapItem)
            return
        }

        foodLookupMessage = nil
        loadingFoodName = row.name
        lookupTask?.cancel()
        lookupTask = Task {
            do {
                let item = try await searchService.place(named: row.name, near: coordinate)
                guard !Task.isCancelled else { return }
                loadingFoodName = nil
                if let item {
                    selectedFood = selection(for: item)
                } else {
                    foodLookupMessage = "Couldn’t find details for \(row.name)."
                }
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                loadingFoodName = nil
                foodLookupMessage = "Couldn’t find details for \(row.name)."
            }
        }
    }

    private func selection(for food: MKMapItem) -> SavedFoodSelection {
        let meters = CLLocation(latitude: stop.latitude, longitude: stop.longitude)
            .distance(from: food.location)
        let feet = Int((meters * 3.28084).rounded())
        let minutes = max(1, Int(ceil(meters / 80)))
        return SavedFoodSelection(
            food: food,
            distanceAndWalk: "\(feet.formatted()) ft · ~\(minutes) min walk"
        )
    }
}
