import MapKit
import SwiftData
import SwiftUI

enum SavedLibrarySection: String, CaseIterable {
    case chargers = "Chargers"
    case food = "Food"
}

// MARK: - Saved stops

struct SavedStopsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedStop.savedAt, order: .reverse) private var savedStops: [SavedStop]
    @Query(sort: \SavedRestaurantChain.savedAt, order: .reverse)
    private var savedChains: [SavedRestaurantChain]
    @Query(sort: \SavedRestaurantLocation.savedAt, order: .reverse)
    private var savedLocations: [SavedRestaurantLocation]

    @State private var showsMap: Bool
    @State private var section: SavedLibrarySection
    @State private var selectedStopID: UUID?
    @State private var cameraPosition: MapCameraPosition = .automatic

    init(showMap: Bool = false, section: SavedLibrarySection = .chargers) {
        _showsMap = State(initialValue: showMap)
        _section = State(initialValue: section)
    }

    private var selectedStop: SavedStop? {
        savedStops.first { $0.id == selectedStopID }
    }

    private var hasSavedFood: Bool {
        !savedChains.isEmpty || !savedLocations.isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Saved library", selection: $section) {
                    ForEach(SavedLibrarySection.allCases, id: \.self) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .top])

                switch section {
                case .chargers:
                    chargersContent
                case .food:
                    foodContent
                }
            }
            .navigationTitle("Saved")
            .onChange(of: savedStops.map(\.id)) { _, _ in
                if selectedStop == nil {
                    selectedStopID = nil
                }
                cameraPosition = .automatic
            }
        }
    }

    @ViewBuilder
    private var chargersContent: some View {
        if savedStops.isEmpty {
            ContentUnavailableView(
                "No Saved Stops",
                systemImage: "bookmark",
                description: Text("Choose a charger on the map, then save it for later.")
            )
        } else {
            VStack(spacing: 0) {
                Picker("Saved stops view", selection: $showsMap) {
                    Label("List", systemImage: "list.bullet").tag(false)
                    Label("Map", systemImage: "map").tag(true)
                }
                .pickerStyle(.segmented)
                .padding()

                if showsMap {
                    savedMap
                } else {
                    List {
                        ForEach(savedStops) { stop in
                            NavigationLink {
                                SavedStopDetailsView(stop: stop)
                            } label: {
                                stopRow(stop)
                            }
                        }
                        .onDelete(perform: deleteStops)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var foodContent: some View {
        if !hasSavedFood {
            ContentUnavailableView(
                "No Saved Restaurants",
                systemImage: "fork.knife",
                description: Text("Open a restaurant from a charging stop, then save the chain or that location.")
            )
        } else {
            List {
                if !savedChains.isEmpty {
                    Section("Chains") {
                        ForEach(savedChains) { chain in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(chain.name)
                                    .font(.headline)
                                Text(chain.savedAt, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteChains)
                    }
                }

                if !savedLocations.isEmpty {
                    Section("Locations") {
                        ForEach(savedLocations) { location in
                            NavigationLink {
                                SavedRestaurantLocationDetailsView(location: location)
                            } label: {
                                locationRow(location)
                            }
                        }
                        .onDelete(perform: deleteLocations)
                    }
                }
            }
        }
    }

    private var savedMap: some View {
        Map(position: $cameraPosition, selection: $selectedStopID) {
            ForEach(savedStops) { stop in
                Marker(
                    stop.chargerName,
                    systemImage: "bolt.fill",
                    coordinate: CLLocationCoordinate2D(
                        latitude: stop.latitude,
                        longitude: stop.longitude
                    )
                )
                .tint(.green)
                .tag(stop.id)
            }
        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .overlay(alignment: .topTrailing) {
            Button {
                withAnimation {
                    cameraPosition = .automatic
                }
            } label: {
                Label("Show all", systemImage: "arrow.up.left.and.arrow.down.right")
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .padding()
            .accessibilityLabel("Show all saved locations")
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let stop = selectedStop {
                VStack(alignment: .trailing, spacing: 0) {
                    Button {
                        selectedStopID = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Close saved stop details")

                    stopRow(stop)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        NavigationLink {
                            SavedStopDetailsView(stop: stop)
                        } label: {
                            Label("View details", systemImage: "info.circle")
                        }
                        .buttonStyle(.bordered)

                        Button {
                            openDirections(to: stop)
                        } label: {
                            Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .tint(.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(.regularMaterial)
            }
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
        }
        .padding(.vertical, 6)
    }

    private func locationRow(_ location: SavedRestaurantLocation) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(location.name)
                    .font(.headline)
                Spacer()
                Text(location.savedAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !location.address.isEmpty {
                Text(location.address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !location.note.isEmpty {
                Text(location.note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    private func deleteStops(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(savedStops[index])
        }
    }

    private func deleteChains(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(savedChains[index])
        }
    }

    private func deleteLocations(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(savedLocations[index])
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
