import MapKit
import SwiftData
import SwiftUI

// MARK: - Charger search

struct SearchView: View {
    private let startingRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.3493, longitude: -74.6597),
        latitudinalMeters: 35_000,
        longitudinalMeters: 35_000
    )

    @Environment(\.modelContext) private var modelContext
    @Query private var savedStops: [SavedStop]
    @State private var cameraPosition: MapCameraPosition
    @State private var destination = ""
    @State private var chargers: [ChargerResult] = []
    @State private var selectedCharger: ChargerResult?
    @State private var nearbyFood: [MKMapItem] = []
    @State private var isSearching = false
    @State private var isLoadingFood = false
    @State private var message: String?

    init() {
        _cameraPosition = State(initialValue: .region(startingRegion))
    }

    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition) {
                ForEach(chargers) { charger in
                    Annotation(charger.name, coordinate: charger.coordinate) {
                        Button {
                            select(charger)
                        } label: {
                            Image(systemName: selectedCharger?.id == charger.id
                                  ? "bolt.circle.fill"
                                  : "bolt.circle")
                                .font(.title)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .green)
                                .padding(4)
                                .background(.black.opacity(0.75), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Select \(charger.name)")
                    }
                }
            }
            .mapStyle(.standard(pointsOfInterest: .including([.evCharger, .restaurant, .cafe])))
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .overlay {
                if isSearching {
                    ProgressView("Finding charging stops…")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .safeAreaInset(edge: .bottom) {
                StopResultPanel(
                    state: panelState,
                    onSave: saveSelectedCharger,
                    onDirections: openSelectedChargerDirections
                )
            }
            .navigationTitle("Feed My EV Trip")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $destination,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Town or destination"
            )
            .onSubmit(of: .search, search)
        }
    }

    private var panelState: StopPanelState {
        guard let selectedCharger else {
            return message.map(StopPanelState.message) ?? .welcome
        }

        let foodOptions = nearbyFood.map { food in
            FoodSummary(
                name: food.name ?? "Food option",
                distanceAndWalk: walkingEstimate(from: selectedCharger, to: food)
            )
        }
        let stop = StopSummary(
            chargerName: selectedCharger.name,
            address: selectedCharger.address,
            foodOptions: foodOptions
        )
        return .selected(
            stop: stop,
            isLoadingFood: isLoadingFood,
            isSaved: isSaved(selectedCharger)
        )
    }

    private func search() {
        let trimmedDestination = destination.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDestination.isEmpty else { return }

        isSearching = true
        message = nil
        selectedCharger = nil
        nearbyFood = []
        isLoadingFood = false

        Task {
            do {
                let destinationRequest = MKLocalSearch.Request()
                destinationRequest.naturalLanguageQuery = trimmedDestination
                let destinationResponse = try await MKLocalSearch(request: destinationRequest).start()

                guard let place = destinationResponse.mapItems.first else {
                    message = "We couldn’t find that destination."
                    isSearching = false
                    return
                }

                let region = MKCoordinateRegion(
                    center: place.location.coordinate,
                    latitudinalMeters: 25_000,
                    longitudinalMeters: 25_000
                )
                cameraPosition = .region(region)

                let chargerRequest = MKLocalSearch.Request()
                chargerRequest.naturalLanguageQuery = "EV charging station"
                chargerRequest.region = region
                let chargerResponse = try await MKLocalSearch(request: chargerRequest).start()

                chargers = chargerResponse.mapItems.map(ChargerResult.init)
                message = chargers.isEmpty
                    ? "No chargers found near \(trimmedDestination)."
                    : "Choose one of \(chargers.count) charging stops."
            } catch {
                message = "Map search isn’t available right now. Please try again."
            }

            isSearching = false
        }
    }

    private func select(_ charger: ChargerResult) {
        let selectedID = charger.id
        selectedCharger = charger
        nearbyFood = []
        isLoadingFood = true

        Task {
            let maximumWalkingDistance: CLLocationDistance = 1_609
            let request = MKLocalPointsOfInterestRequest(
                center: charger.coordinate,
                radius: maximumWalkingDistance
            )
            request.pointOfInterestFilter = MKPointOfInterestFilter(including: [
                .restaurant,
                .cafe,
                .bakery
            ])

            do {
                let response = try await MKLocalSearch(request: request).start()
                let localResults = response.mapItems
                    .filter {
                        charger.mapItem.location.distance(from: $0.location)
                            <= maximumWalkingDistance
                    }
                    .sorted {
                        charger.mapItem.location.distance(from: $0.location)
                            < charger.mapItem.location.distance(from: $1.location)
                    }

                guard selectedCharger?.id == selectedID else { return }
                nearbyFood = localResults
            } catch {
                guard selectedCharger?.id == selectedID else { return }
                nearbyFood = []
            }

            if selectedCharger?.id == selectedID {
                isLoadingFood = false
            }
        }
    }

    private func walkingEstimate(from charger: ChargerResult, to food: MKMapItem) -> String {
        let meters = charger.mapItem.location.distance(from: food.location)
        let feet = Int((meters * 3.28084).rounded())
        let minutes = max(1, Int(ceil(meters / 80)))
        return "\(feet.formatted()) ft · ~\(minutes) min walk"
    }

    private func openSelectedChargerDirections() {
        guard let selectedCharger else { return }
        selectedCharger.mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    private func isSaved(_ charger: ChargerResult) -> Bool {
        savedStops.contains {
            abs($0.latitude - charger.coordinate.latitude) < 0.000_001
                && abs($0.longitude - charger.coordinate.longitude) < 0.000_001
        }
    }

    private func saveSelectedCharger() {
        guard let selectedCharger, !isSaved(selectedCharger) else { return }

        let stop = SavedStop(
            chargerName: selectedCharger.name,
            address: selectedCharger.address,
            latitude: selectedCharger.coordinate.latitude,
            longitude: selectedCharger.coordinate.longitude,
            foodNames: nearbyFood.prefix(3).compactMap(\.name)
        )
        modelContext.insert(stop)
    }
}

#Preview {
    SearchView()
        .modelContainer(for: SavedStop.self, inMemory: true)
}
