import MapKit
import SwiftData
import SwiftUI

// MARK: - Saved stops

struct SavedStopsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedStop.savedAt, order: .reverse) private var savedStops: [SavedStop]

    @State private var showsMap: Bool
    @State private var selectedStopID: UUID?
    @State private var cameraPosition: MapCameraPosition = .automatic

    init(showMap: Bool = false) {
        _showsMap = State(initialValue: showMap)
    }

    private var selectedStop: SavedStop? {
        savedStops.first { $0.id == selectedStopID }
    }

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
                                    stopRow(stop)
                                }
                                .onDelete(perform: delete)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Saved Stops")
            .onChange(of: savedStops.map(\.id)) { _, _ in
                if selectedStop == nil {
                    selectedStopID = nil
                }
                cameraPosition = .automatic
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
