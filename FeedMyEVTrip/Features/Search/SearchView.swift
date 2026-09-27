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
    @StateObject private var locationService = LocationService()
    @StateObject private var searchService = MapSearchService()
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
    @State private var areaSearchTask: Task<Void, Never>?
    @State private var foodSearchTask: Task<Void, Never>?

    init() {
        _cameraPosition = State(initialValue: .region(startingRegion))
    }

    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition) {
                UserAnnotation()

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
                            Button {
                                selectFoodDetails(food)
                            } label: {
                                Image(systemName: "fork.knife.circle.fill")
                                    .font(.title2)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .orange)
                                    .padding(3)
                                    .background(.black.opacity(0.75), in: Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("View details for \(food.name ?? "food option")")
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
                if showsSearchHere && !isSearching && !isShowingStopArea {
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
            .overlay(alignment: .topLeading) {
                if isShowingStopArea {
                    Button(action: toggleMapDetail) {
                        Label("Back to area", systemImage: "chevron.backward")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(.regularMaterial, in: Capsule())
                            .shadow(radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 12)
                    .padding(.leading, 12)
                }
            }
            .overlay(alignment: .topTrailing) {
                if !isShowingStopArea {
                    Button(action: locationService.requestCurrentLocation) {
                        Image(systemName: "location.fill")
                            .font(.headline)
                            .padding(11)
                            .background(.regularMaterial, in: Circle())
                            .shadow(radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Search near my location")
                    .padding(.top, 12)
                    .padding(.trailing, 12)
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
            .onChange(of: locationService.location?.timestamp) { _, _ in
                centerOnCurrentLocation()
            }
            .sheet(item: $selectedFoodDetails) { selection in
                FoodDetailsView(
                    food: selection.mapItem,
                    distanceAndWalk: selection.distanceAndWalk
                )
                .presentationDetents([.medium, .large])
            }
            .alert(
                "Location unavailable",
                isPresented: Binding(
                    get: { locationService.errorMessage != nil },
                    set: { if !$0 { locationService.clearError() } }
                )
            ) {
                Button("OK", role: .cancel) {
                    locationService.clearError()
                }
            } message: {
                Text(locationService.errorMessage ?? "Please try again.")
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

        cancelActiveSearches()
        isSearching = true
        message = nil
        chargers = []
        selectedCharger = nil
        nearbyFood = []
        isLoadingFood = false
        isShowingStopArea = false
        overviewRegion = nil

        areaSearchTask = Task {
            do {
                guard let place = try await searchService.resolveDestination(trimmedDestination) else {
                    message = "We couldn’t find that destination."
                    isSearching = false
                    return
                }

                let region = MKCoordinateRegion(
                    center: place.mapItem.location.coordinate,
                    latitudinalMeters: 10_000,
                    longitudinalMeters: 10_000
                )
                suppressesNextCameraPrompt = true
                showsSearchHere = false
                withAnimation(.easeInOut(duration: 0.45)) {
                    cameraPosition = .region(region)
                }
                try Task.checkCancellation()
                await loadChargers(in: region, areaName: trimmedDestination)
            } catch is CancellationError {
                return
            } catch {
                message = searchMessage(for: error)
            }

            isSearching = false
        }
    }

    private func searchVisibleRegion() {
        guard let visibleRegion else { return }

        cancelActiveSearches()
        showsSearchHere = false
        isSearching = true
        message = nil
        selectedCharger = nil
        nearbyFood = []
        isLoadingFood = false
        isShowingStopArea = false
        overviewRegion = nil

        areaSearchTask = Task {
            await loadChargers(
                in: visibleRegion,
                areaName: "this area"
            )
            isSearching = false
        }
    }

    private func centerOnCurrentLocation() {
        guard let location = locationService.location else { return }

        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 10_000,
            longitudinalMeters: 10_000
        )
        suppressesNextCameraPrompt = true
        showsSearchHere = false
        selectedCharger = nil
        chargers = []
        nearbyFood = []
        isShowingStopArea = false
        overviewRegion = nil
        isSearching = true

        withAnimation(.easeInOut(duration: 0.45)) {
            cameraPosition = .region(region)
        }

        cancelActiveSearches()
        areaSearchTask = Task {
            await loadChargers(
                in: region,
                areaName: "your location"
            )
            isSearching = false
        }
    }

    private func loadChargers(
        in region: MKCoordinateRegion,
        areaName: String
    ) async {
        do {
            let places = try await searchService.searchChargers(in: region)
            try Task.checkCancellation()
            chargers = mergeChargers(
                existing: chargers,
                new: places.map {
                    ChargerResult(
                        mapItem: $0.mapItem,
                        placeIdentifier: $0.identifier
                    )
                }
            )
            message = chargers.isEmpty
                ? "No chargers found near \(areaName)."
                : "Choose one of \(chargers.count) charging stops."
        } catch is CancellationError {
            return
        } catch {
            message = searchMessage(for: error)
        }
    }

    private func select(_ charger: ChargerResult) {
        let selectedID = charger.id
        selectedCharger = charger
        nearbyFood = []
        isLoadingFood = true
        isShowingStopArea = false
        overviewRegion = nil

        foodSearchTask?.cancel()
        searchService.cancelActiveSearch()
        foodSearchTask = Task {
            let maximumWalkingDistance = CLLocationDistance(maximumWalkingMinutes * 80)

            do {
                let places = try await searchService.searchFood(
                    around: charger.coordinate,
                    radius: maximumWalkingDistance,
                    categories: selectedFoodCategories
                )
                let localResults = places.map(\.mapItem)
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
            } catch is CancellationError {
                return
            } catch {
                guard selectedCharger?.id == selectedID else { return }
                nearbyFood = []
                message = searchMessage(for: error)
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
        selectFoodDetails(food)
    }

    private func selectFoodDetails(_ food: MKMapItem) {
        guard let selectedCharger else { return }
        selectedFoodDetails = SelectedFood(
            mapItem: food,
            distanceAndWalk: walkingEstimate(from: selectedCharger, to: food)
        )
    }

    private func toggleMapDetail() {
        if isShowingStopArea {
            guard let overviewRegion else { return }
            suppressesNextCameraPrompt = true
            withAnimation(.easeInOut(duration: 0.45)) {
                cameraPosition = .region(overviewRegion)
            }
            isShowingStopArea = false
            self.overviewRegion = nil
            return
        }

        guard let selectedCharger, !nearbyFood.isEmpty else { return }
        overviewRegion = visibleRegion

        let furthestDisplayedDistance = nearbyFood
            .prefix(3)
            .map { selectedCharger.mapItem.location.distance(from: $0.location) }
            .max() ?? 200
        let visibleDiameter = max(furthestDisplayedDistance * 2, 400)
        let stopAreaRegion = MKCoordinateRegion(
            center: selectedCharger.coordinate,
            latitudinalMeters: visibleDiameter,
            longitudinalMeters: visibleDiameter
        )

        suppressesNextCameraPrompt = true
        showsSearchHere = false
        withAnimation(.easeInOut(duration: 0.45)) {
            cameraPosition = .region(stopAreaRegion)
        }
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
            mapItemIdentifier: selectedCharger.placeIdentifier,
            foodNames: nearbyFood.prefix(3).compactMap(\.name)
        )
        modelContext.insert(stop)
    }

    private func cancelActiveSearches() {
        areaSearchTask?.cancel()
        foodSearchTask?.cancel()
        searchService.cancelActiveSearch()
    }

    private func mergeChargers(
        existing: [ChargerResult],
        new: [ChargerResult]
    ) -> [ChargerResult] {
        var coordinateKeys = Set<String>()
        return (existing + new).filter { charger in
            let coordinate = charger.coordinate
            let key = "\(Int((coordinate.latitude * 100_000).rounded())):"
                + "\(Int((coordinate.longitude * 100_000).rounded()))"
            return coordinateKeys.insert(key).inserted
        }
    }

    private func searchMessage(for error: Error) -> String {
        switch error {
        case MapSearchFailure.throttled:
            return "Map search is temporarily limited. Please try again shortly."
        case MapSearchFailure.networkUnavailable:
            return "You appear to be offline. Check your connection and try again."
        default:
            return "Map search isn’t available right now. Please try again."
        }
    }
}

#Preview {
    SearchView()
        .modelContainer(for: SavedStop.self, inMemory: true)
}
