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
    @AppStorage(FoodPreferenceKeys.maximumWalkingMinutes)
    private var maximumWalkingMinutes = 15
    @AppStorage(FoodPreferenceKeys.includesRestaurants)
    private var includesRestaurants = true
    @AppStorage(FoodPreferenceKeys.includesCafes)
    private var includesCafes = true
    @AppStorage(FoodPreferenceKeys.includesBakeries)
    private var includesBakeries = true
    @State private var cameraPosition: MapCameraPosition
    @State private var destination = ""
    @State private var chargers: [ChargerResult] = []
    @State private var selectedCharger: ChargerResult?
    @State private var nearbyFood: [MKMapItem] = []
    @State private var isSearching = false
    @State private var isLoadingFood = false
    @State private var message: String?
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var showsSearchHere = false
    @State private var suppressesNextCameraPrompt = true
    @State private var isShowingStopArea = false
    @State private var overviewRegion: MKCoordinateRegion?
    @State private var selectedFoodDetails: SelectedFood?

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

                if isShowingStopArea {
                    ForEach(Array(nearbyFood.prefix(3).enumerated()), id: \.offset) { _, food in
                        Annotation(food.name ?? "Food", coordinate: food.location.coordinate) {
                            Image(systemName: "fork.knife.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .orange)
                                .padding(3)
                                .background(.black.opacity(0.75), in: Circle())
                        }
                    }
                }
            }
            .mapStyle(.standard(pointsOfInterest: .including([.evCharger, .restaurant, .cafe])))
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                visibleRegion = context.region

                if suppressesNextCameraPrompt {
                    suppressesNextCameraPrompt = false
                } else {
                    showsSearchHere = true
                }
            }
            .overlay(alignment: .top) {
                if showsSearchHere && !isSearching {
                    Button(action: searchVisibleRegion) {
                        Label("Search Here", systemImage: "magnifyingglass")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .contentShape(Capsule())
                            .background(.regularMaterial, in: Capsule())
                            .shadow(radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Capsule())
                    .zIndex(10)
                    .padding(.top, 12)
                }
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
                    onDirections: openSelectedChargerDirections,
                    onToggleMapDetail: toggleMapDetail,
                    onSelectFood: selectFoodDetails
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
            .sheet(item: $selectedFoodDetails) { selection in
                FoodDetailsView(
                    food: selection.mapItem,
                    distanceAndWalk: selection.distanceAndWalk
                )
                .presentationDetents([.medium, .large])
            }
        }
    }

    private var panelState: StopPanelState {
        guard let selectedCharger else {
            return message.map(StopPanelState.message) ?? .welcome
        }

        let foodOptions = nearbyFood.map { food in
            FoodSummary(
                id: foodIdentifier(food),
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
            isSaved: isSaved(selectedCharger),
            isShowingStopArea: isShowingStopArea
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
        isShowingStopArea = false
        overviewRegion = nil

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
                    latitudinalMeters: 10_000,
                    longitudinalMeters: 10_000
                )
                suppressesNextCameraPrompt = true
                showsSearchHere = false
                cameraPosition = .region(region)
                await loadChargers(in: region, areaName: trimmedDestination)
            } catch {
                message = "Map search isn’t available right now. Please try again."
            }

            isSearching = false
        }
    }

    private func searchVisibleRegion() {
        guard let visibleRegion else { return }

        showsSearchHere = false
        isSearching = true
        message = nil
        selectedCharger = nil
        nearbyFood = []
        isLoadingFood = false
        isShowingStopArea = false
        overviewRegion = nil

        Task {
            await loadChargers(in: visibleRegion, areaName: "this area")
            isSearching = false
        }
    }

    private func loadChargers(in region: MKCoordinateRegion, areaName: String) async {
        var mapItems: [MKMapItem] = []

        for searchRegion in searchRegions(covering: region) {
            let request = MKLocalPointsOfInterestRequest(coordinateRegion: searchRegion)
            request.pointOfInterestFilter = MKPointOfInterestFilter(including: [
                .evCharger
            ])
            do {
                let response = try await MKLocalSearch(request: request).start()
                mapItems.append(contentsOf: response.mapItems)
            } catch {
                // A region with no matching POIs can fail independently. Keep any
                // useful results returned by the other regions.
                continue
            }
        }

        var locationKeys = Set<String>()
        let centerLocation = CLLocation(
            latitude: region.center.latitude,
            longitude: region.center.longitude
        )
        let uniqueMapItems = mapItems
            .filter { item in
                let coordinate = item.location.coordinate
                let key = "\(Int((coordinate.latitude * 100_000).rounded())):"
                    + "\(Int((coordinate.longitude * 100_000).rounded()))"
                return locationKeys.insert(key).inserted
            }
            .sorted {
                centerLocation.distance(from: $0.location)
                    < centerLocation.distance(from: $1.location)
            }

        chargers = uniqueMapItems.map(ChargerResult.init)
        message = chargers.isEmpty
            ? "No chargers found near \(areaName)."
            : "Choose one of \(chargers.count) charging stops."
    }

    private func searchRegions(covering region: MKCoordinateRegion) -> [MKCoordinateRegion] {
        let cellSpan = MKCoordinateSpan(
            latitudeDelta: region.span.latitudeDelta / 2,
            longitudeDelta: region.span.longitudeDelta / 2
        )
        let latitudeOffset = region.span.latitudeDelta / 4
        let longitudeOffset = region.span.longitudeDelta / 4

        return [-1.0, 1.0].flatMap { latitudeDirection in
            [-1.0, 1.0].map { longitudeDirection in
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: region.center.latitude + latitudeOffset * latitudeDirection,
                        longitude: region.center.longitude + longitudeOffset * longitudeDirection
                    ),
                    span: cellSpan
                )
            }
        }
    }

    private func select(_ charger: ChargerResult) {
        let selectedID = charger.id
        selectedCharger = charger
        nearbyFood = []
        isLoadingFood = true
        isShowingStopArea = false
        overviewRegion = nil

        Task {
            let maximumWalkingDistance = CLLocationDistance(maximumWalkingMinutes * 80)
            let request = MKLocalPointsOfInterestRequest(
                center: charger.coordinate,
                radius: maximumWalkingDistance
            )
            request.pointOfInterestFilter = MKPointOfInterestFilter(
                including: selectedFoodCategories
            )

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

    private func foodIdentifier(_ food: MKMapItem) -> String {
        let coordinate = food.location.coordinate
        return "\(coordinate.latitude):\(coordinate.longitude):\(food.name ?? "")"
    }

    private func selectFoodDetails(_ summary: FoodSummary) {
        guard let food = nearbyFood.first(where: { foodIdentifier($0) == summary.id }) else {
            return
        }
        selectedFoodDetails = SelectedFood(
            mapItem: food,
            distanceAndWalk: summary.distanceAndWalk
        )
    }

    private func toggleMapDetail() {
        if isShowingStopArea {
            guard let overviewRegion else { return }
            suppressesNextCameraPrompt = true
            cameraPosition = .region(overviewRegion)
            isShowingStopArea = false
            self.overviewRegion = nil
            return
        }

        guard let selectedCharger, !nearbyFood.isEmpty else { return }
        overviewRegion = visibleRegion

        let walkingRadius = CLLocationDistance(maximumWalkingMinutes * 80)
        let visibleDiameter = max(walkingRadius * 2.4, 800)
        let stopAreaRegion = MKCoordinateRegion(
            center: selectedCharger.coordinate,
            latitudinalMeters: visibleDiameter,
            longitudinalMeters: visibleDiameter
        )

        suppressesNextCameraPrompt = true
        showsSearchHere = false
        cameraPosition = .region(stopAreaRegion)
        isShowingStopArea = true
    }

    private var selectedFoodCategories: [MKPointOfInterestCategory] {
        var categories: [MKPointOfInterestCategory] = []
        if includesRestaurants { categories.append(.restaurant) }
        if includesCafes { categories.append(.cafe) }
        if includesBakeries { categories.append(.bakery) }
        return categories.isEmpty ? [.restaurant] : categories
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
