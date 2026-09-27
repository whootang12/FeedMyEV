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
    @Query private var savedChains: [SavedRestaurantChain]
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
    @State private var routeDestination = ""
    @State private var resultAreaName = "your location"
    @State private var isEditingSearch = true
    @State private var searchMode = SearchMode.route
    @State private var panelSize = PanelSize.medium
    @State private var hasSearched = false
    @State private var waitingForNearbyLocation = false
    @State private var resultsRegion: MKCoordinateRegion?

    private enum SearchMode: String, CaseIterable {
        case route = "Along a route", nearby = "Near a place"
    }
    private enum PanelSize { case compact, medium, expanded }
    @State private var routeResults: RouteStopResults?
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
    @State private var chargerNoteDraft = ""
    @State private var isSyncingChargerNote = false
    @State private var areaSearchTask: Task<Void, Never>?
    @State private var foodSearchTask: Task<Void, Never>?

    init() {
        _cameraPosition = State(initialValue: .region(startingRegion))
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                mapView
                searchPanel
                    .frame(height: panelHeight(available: geometry.size.height))
                    .background(.regularMaterial)
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24))
            }
            .background(.regularMaterial)
        }
        .onChange(of: locationService.location?.timestamp) { _, _ in
            guard waitingForNearbyLocation else { return }
            waitingForNearbyLocation = false
            centerOnCurrentLocation()
        }
        .onChange(of: chargerNoteDraft) { _, newValue in
            if isSyncingChargerNote {
                isSyncingChargerNote = false
                return
            }
            persistChargerNote(newValue)
        }
        .onChange(of: isLoadingFood) { _, isLoading in
            if !isLoading { persistChargerNote(chargerNoteDraft) }
        }
        .sheet(item: $selectedFoodDetails) { selection in
            FoodDetailsView(
                food: selection.mapItem,
                charger: selection.charger,
                distanceAndWalk: selection.distanceAndWalk
            )
                .presentationDetents([.medium, .large])
        }
        .alert("Location unavailable", isPresented: Binding(
            get: { locationService.errorMessage != nil },
            set: { if !$0 { locationService.clearError(); waitingForNearbyLocation = false } }
        )) {
            Button("OK", role: .cancel) { locationService.clearError(); waitingForNearbyLocation = false }
        } message: {
            Text(locationService.errorMessage ?? "Please try again.")
        }
    }

    private var mapView: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
            if let results = routeResults {
                MapPolyline(results.route.polyline).stroke(.blue.opacity(0.55), lineWidth: 5)
                MapPolyline(results.stopSegment).stroke(.orange, lineWidth: 7)
                Marker("Start", systemImage: "play.fill", coordinate: results.startCoordinate).tint(.blue)
                Marker("Destination: \(results.destinationName)", systemImage: "flag.checkered", coordinate: results.destinationCoordinate).tint(.red)
            }
            ForEach(chargers) { charger in
                Annotation(charger.name, coordinate: charger.coordinate) {
                    Button { select(charger) } label: {
                        Image(systemName: isSaved(charger) ? "bookmark.circle.fill" : "bolt.circle.fill")
                            .font(selectedCharger?.id == charger.id ? .largeTitle : .title)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, isSaved(charger) ? .purple : .green)
                            .padding(4)
                            .background(.black.opacity(0.7), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Select \(isSaved(charger) ? "saved charger " : "")\(charger.name)")
                }
            }
            if isShowingStopArea {
                ForEach(Array(nearbyFood.prefix(3).enumerated()), id: \.offset) { _, food in
                    Annotation(food.name ?? "Food", coordinate: food.location.coordinate) {
                        Button { selectFoodDetails(food) } label: {
                            Image(systemName: "fork.knife.circle.fill")
                                .font(.title2).foregroundStyle(.orange)
                                .background(.white, in: Circle())
                        }
                        .accessibilityLabel("View \(food.name ?? "food option")")
                    }
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .mapControls { MapCompass(); MapScaleView() }
        .onMapCameraChange(frequency: .onEnd) { context in
            visibleRegion = context.region
            if suppressesNextCameraPrompt { suppressesNextCameraPrompt = false }
            else if hasSearched { showsSearchHere = true }
        }
        .overlay(alignment: .top) {
            if showsSearchHere && routeResults == nil && searchMode == .nearby && !isEditingSearch && selectedCharger == nil && !isSearching {
                Button("Search this area", action: searchVisibleRegion)
                    .buttonStyle(.borderedProminent).padding(10)
            }
        }
    }

    private func panelHeight(available: CGFloat) -> CGFloat {
        switch panelSize {
        case .compact: return min(160, available * 0.3)
        case .medium: return available * 0.52
        case .expanded: return available * 0.88
        }
    }

    private var searchPanel: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                Capsule().fill(.secondary.opacity(0.5)).frame(width: 40, height: 5)
                HStack {
                    if selectedCharger != nil {
                        Button(action: returnToResults) { Label("Results", systemImage: "chevron.left") }
                        Spacer()
                        Text("Charging stop").font(.headline)
                    } else {
                        Text(isEditingSearch ? "Search" : "Charging stops").font(.title3.bold())
                        Spacer()
                        if isEditingSearch && hasSearched {
                            Button("Back to results") { isEditingSearch = false; panelSize = .medium }
                        } else if !isEditingSearch {
                            Button("Edit search", action: editSearch)
                        }
                    }
                    Button {
                        withAnimation { panelSize = panelSize == .expanded ? .medium : .expanded }
                    } label: {
                        Image(systemName: panelSize == .expanded ? "chevron.down" : "chevron.up")
                    }
                    .accessibilityLabel(panelSize == .expanded ? "Collapse panel" : "Expand panel")
                }
            }
            .padding()
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 20).onEnded { value in
                withAnimation {
                    if value.translation.height < -25 { panelSize = panelSize == .compact ? .medium : .expanded }
                    if value.translation.height > 25 { panelSize = panelSize == .expanded ? .medium : .compact }
                }
            })

            if isEditingSearch {
                Picker("Search mode", selection: $searchMode) {
                    ForEach(SearchMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented).padding(.horizontal)
                if searchMode == .route {
                    FindMyStopView(destination: $routeDestination, onResults: showRouteResults)
                } else {
                    Form {
                        Section("Search nearby") {
                            TextField("Town or address", text: $destination)
                                .onSubmit(search)
                            Button("Search", action: search)
                                .disabled(destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            Button {
                                waitingForNearbyLocation = true
                                locationService.requestCurrentLocation()
                            } label: { Label("Use my location", systemImage: "location.fill") }
                        }
                    }
                }
            } else if selectedCharger != nil {
                ScrollView {
                    if let stop = routeResults?.stops.first(where: { $0.id == selectedCharger?.id }) {
                        Text(stop.summary).font(.caption).padding(.horizontal)
                    }
                    StopResultPanel(
                        state: panelState,
                        note: $chargerNoteDraft,
                        onSave: saveSelectedCharger,
                        onDirections: openSelectedChargerDirections,
                        onToggleMapDetail: toggleMapDetail,
                        onSelectFood: selectFoodDetails
                    )
                }
            } else {
                resultsList
            }
        }
    }

    private var resultsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let results = routeResults {
                    Text("To \(results.destinationName)").font(.headline)
                    Text(results.windowDescription).font(.subheadline)
                    Label("Orange shows the approximate stop window", systemImage: "line.diagonal")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("Near \(resultAreaName)").font(.headline)
                }
                if isSearching { ProgressView("Finding chargers…") }
                if let message { Text(message).font(.subheadline).foregroundStyle(.secondary) }
                ForEach(chargers) { charger in
                    Button { select(charger) } label: {
                        HStack {
                            Image(systemName: isSaved(charger) ? "bookmark.fill" : "bolt.fill")
                                .foregroundStyle(isSaved(charger) ? .purple : .green)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(charger.name).font(.headline)
                                if isSaved(charger) { Text("Saved charger").font(.caption).foregroundStyle(.purple) }
                                if let stop = routeResults?.stops.first(where: { $0.id == charger.id }) {
                                    Text(stop.summary).font(.caption)
                                } else { Text(charger.address).font(.caption) }
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.secondary)
                        }
                        .padding().frame(maxWidth: .infinity, alignment: .leading)
                        .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                if let notice = routeResults?.notice { Text(notice).font(.caption).foregroundStyle(.secondary) }
            }
            .padding()
        }
    }

    private func editSearch() {
        cancelActiveSearches()
        isSearching = false
        isEditingSearch = true
        panelSize = .medium
    }

    private func returnToResults() {
        foodSearchTask?.cancel()
        searchService.cancelActiveSearch()
        selectedCharger = nil
        nearbyFood = []
        isLoadingFood = false
        isShowingStopArea = false
        overviewRegion = nil
        suppressesNextCameraPrompt = true
        if let resultsRegion { cameraPosition = .region(resultsRegion) }
        panelSize = .medium
    }

    private func showRouteResults(_ results: RouteStopResults) {
        cancelActiveSearches()
        routeResults = results
        isEditingSearch = false
        hasSearched = true
        panelSize = .medium
        chargers = results.stops.map(\.charger)
        selectedCharger = nil
        nearbyFood = []
        isSearching = false
        isLoadingFood = false
        isShowingStopArea = false
        overviewRegion = nil
        showsSearchHere = false
        suppressesNextCameraPrompt = true
        message = results.stops.isEmpty
            ? "No matching stops found. Try a wider window or a larger detour allowance."
            : "Select a stop to check nearby food and save it."
        let rect = results.route.polyline.boundingMapRect
        cameraPosition = .rect(rect.insetBy(dx: -rect.width * 0.12, dy: -rect.height * 0.12))
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
            foodOptions: foodOptions,
            metadata: selectedCharger.metadataSummary
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
        resultAreaName = trimmedDestination
        isEditingSearch = false
        hasSearched = true
        panelSize = .medium
        routeResults = nil
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
        routeResults = nil
        chargers = []
        resultAreaName = "this area"

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
        resultAreaName = "your location"
        isEditingSearch = false
        hasSearched = true
        panelSize = .medium
        routeResults = nil

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
            let found = try await AFDCChargerProvider.shared.chargers(in: region)
            try Task.checkCancellation()
            chargers = found.filter { ChargerConnector.allows($0.connectorCodes) }
            message = chargers.isEmpty
                ? (found.isEmpty
                    ? "No chargers found near \(areaName)."
                    : "No chargers near \(areaName) match your connector preferences.")
                : "Choose one of \(chargers.count) charging stops."
            if let warning = AFDCChargerProvider.shared.warning {
                message = (message ?? "") + " " + warning
            }
        } catch is CancellationError {
            return
        } catch {
            message = searchMessage(for: error)
        }
    }

    private func select(_ charger: ChargerResult) {
        let selectedID = charger.id
        if selectedCharger == nil { resultsRegion = visibleRegion }
        isEditingSearch = false
        panelSize = .medium
        selectedCharger = charger
        replaceChargerNoteDraft(matchingSavedStop(for: charger)?.note ?? "")
        nearbyFood = []
        isLoadingFood = true
        isShowingStopArea = false
        overviewRegion = nil

        areaSearchTask?.cancel()
        isSearching = false
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
                let localResults = NearbyFoodOrdering.sorted(
                    places.map(\.mapItem).filter {
                        charger.mapItem.location.distance(from: $0.location)
                            <= maximumWalkingDistance
                    },
                    from: charger.mapItem.location,
                    savedChains: savedChains
                )

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
            charger: selectedCharger.mapItem,
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
        savedStops.contains { charger.matches(ChargerResult(savedStop: $0)) }
    }

    private func saveSelectedCharger() {
        guard let selectedCharger, matchingSavedStop(for: selectedCharger) == nil else { return }
        insertSavedCharger(selectedCharger, note: chargerNoteDraft)
    }

    private func persistChargerNote(_ text: String) {
        guard let selectedCharger else { return }
        if let existing = matchingSavedStop(for: selectedCharger) {
            if existing.note != text { existing.note = text }
            return
        }
        guard !text.isEmpty, !isLoadingFood else { return }
        insertSavedCharger(selectedCharger, note: text)
    }

    private var savedNearbyFood: [SavedNearbyFood] {
        nearbyFood.prefix(3).compactMap(SavedNearbyFood.init(mapItem:))
    }

    private func replaceChargerNoteDraft(_ text: String) {
        guard chargerNoteDraft != text else { return }
        isSyncingChargerNote = true
        chargerNoteDraft = text
    }

    private func matchingSavedStop(for charger: ChargerResult) -> SavedStop? {
        let stops = (try? modelContext.fetch(FetchDescriptor<SavedStop>())) ?? savedStops
        return stops.first { charger.matches(ChargerResult(savedStop: $0)) }
    }

    private func insertSavedCharger(_ charger: ChargerResult, note: String) {
        let stop = SavedStop(
            chargerName: charger.name,
            address: charger.address,
            latitude: charger.coordinate.latitude,
            longitude: charger.coordinate.longitude,
            mapItemIdentifier: charger.placeIdentifier,
            afdcStationID: charger.afdcStationID,
            foodNames: [],
            nearbyFood: savedNearbyFood,
            note: note
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
        case let error as AFDCCatalogError:
            return error.localizedDescription
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
        .modelContainer(for: SavedStore.modelTypes, inMemory: true)
}
