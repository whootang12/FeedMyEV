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
    @StateObject private var locationCompleter = LocationSearchCompleter()
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
    @State private var isPlaceSearchPresented = false
    @State private var selectedDestinationPlace: SearchPlace?
    @State private var selectedDestinationSubtitle: String?
    @State private var destinationSelectionTask: Task<Void, Never>?
    @State private var routeDestination = ""
    @State private var resultAreaName = "your location"
    @State private var isEditingSearch = true
    @State private var searchMode = SearchMode.nearby
    @State private var showsNearbyResults = false
    @State private var panelSize = SearchDrawerSize.compact
    @State private var hasSearched = false
    @State private var waitingForNearbyLocation = false
    @State private var searchesAfterLocationRequest = false
    @State private var resultsRegion: MKCoordinateRegion?

    private enum SearchMode: String, CaseIterable {
        case route = "Along a route", nearby = "Near a place"
    }
    private enum ResultsTab: CaseIterable, Identifiable {
        case results, restaurants, charging

        var id: Self { self }
        var systemImage: String {
            switch self {
            case .results: "list.bullet"
            case .restaurants: "fork.knife"
            case .charging: "bolt.fill"
            }
        }
        var accessibilityTitle: LocalizedStringKey {
            switch self {
            case .results: "Charging results"
            case .restaurants: "Restaurant preferences"
            case .charging: "Charging needs"
            }
        }
    }
    @State private var routeResults: RouteStopResults?
    @State private var resultsTab = ResultsTab.results
    @State private var isResultsStopWindowExpanded = false
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
            ZStack(alignment: .bottom) {
                mapView
                    .ignoresSafeArea(edges: .top)

                if showsSearchHere && routeResults == nil && searchMode == .nearby && selectedCharger == nil && !isSearching {
                    Button("Search here", action: searchVisibleRegion)
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.top, geometry.safeAreaInsets.top + 10)
                }

                SearchDrawerSurface(
                    size: $panelSize,
                    availableHeight: geometry.size.height
                ) {
                    searchPanel
                }
            }
        }
        .onChange(of: locationService.location?.timestamp) { _, _ in
            guard waitingForNearbyLocation else { return }
            waitingForNearbyLocation = false
            if searchesAfterLocationRequest {
                searchesAfterLocationRequest = false
                centerOnCurrentLocation()
            } else {
                moveMapToCurrentLocation()
            }
        }
        .onChange(of: chargerNoteDraft) { _, newValue in
            if isSyncingChargerNote {
                isSyncingChargerNote = false
                return
            }
            persistChargerNote(newValue)
        }
        .onChange(of: destination) { _, query in
            guard isPlaceSearchPresented else { return }
            locationCompleter.update(query: query, region: visibleRegion)
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
        .onDisappear {
            destinationSelectionTask?.cancel()
            locationCompleter.clear()
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
            else if routeResults == nil && searchMode == .nearby && selectedCharger == nil {
                showsSearchHere = true
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                searchesAfterLocationRequest = false
                if locationService.location != nil {
                    moveMapToCurrentLocation()
                } else {
                    waitingForNearbyLocation = true
                    locationService.requestCurrentLocation()
                }
            } label: {
                Image(systemName: "location.fill")
                    .font(.body.weight(.semibold))
                    .frame(width: 42, height: 42)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.12), radius: 5, y: 2)
            .padding(.trailing, 12)
            .padding(.bottom, panelSize.height(availableHeight: 800) + 12)
            .accessibilityLabel("Go to current location")
        }
    }

    private var searchPanel: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                SearchDrawerHandle()

                if showsDrawerHeader {
                    HStack {
                        if selectedCharger != nil {
                            Button(action: returnToResults) { Label("Results", systemImage: "chevron.left") }
                            Spacer()
                            Text("Charging stop").font(.headline)
                            Button {
                                withAnimation { panelSize = panelSize == .expanded ? .medium : .expanded }
                            } label: {
                                Image(systemName: panelSize == .expanded ? "chevron.down" : "chevron.up")
                            }
                            .accessibilityLabel(panelSize == .expanded ? "Collapse panel" : "Expand panel")
                        } else if isEditingSearch && searchMode == .route {
                            Text("Route").font(.title3.bold())
                            Spacer()
                            drawerCloseButton("Close route", action: closeRoutePlanning)
                        } else if showsNearbyResults {
                            Text("Nearby Chargers").font(.title3.bold())
                            Spacer()
                            drawerCloseButton("Close nearby chargers", action: closeNearbyResults)
                        } else if !isEditingSearch, routeResults != nil {
                            Text("Route").font(.title3.bold())
                            Spacer()
                            drawerCloseButton("Close results", action: closeResults)
                        } else if selectedDestinationPlace != nil {
                            Text(destination).font(.title3.bold()).lineLimit(1)
                            Spacer()
                            drawerCloseButton("Clear destination", action: clearSelectedDestination)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
            .contentShape(Rectangle())

            if isPlaceSearchPresented {
                PlaceSearchPanel(
                    query: $destination,
                    suggestions: locationCompleter.suggestions,
                    onCancel: cancelPlaceSearch,
                    onSelect: selectLocationSuggestion
                )
            } else if isEditingSearch && searchMode == .route {
                FindMyStopView(destination: $routeDestination, onResults: showRouteResults)
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
            } else if showsNearbyResults {
                resultsList(includesStopWindow: false)
            } else if let selectedDestinationPlace {
                SelectedDestinationPanel(
                    subtitle: selectedDestinationSubtitle,
                    distance: distanceDescription(to: selectedDestinationPlace),
                    driveTime: "3h 14min",
                    maximumWalkingMinutes: maximumWalkingMinutes,
                    onRoute: startRouteToSelectedDestination,
                    onNearbyChargers: searchNearbySelectedDestination
                )
            } else if routeResults != nil {
                resultsList(includesStopWindow: true)
            } else {
                startingDrawer
            }
        }
    }

    private var startingDrawer: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SearchLocationBar(text: $destination, onSearch: search, onFocus: beginPlaceSearch)
                SearchPreferenceSections(maximumWalkingMinutes: maximumWalkingMinutes)
                    .padding(.horizontal, 16)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private var showsDrawerHeader: Bool {
        selectedCharger != nil
            || (isEditingSearch && searchMode == .route)
            || showsNearbyResults
            || selectedDestinationPlace != nil
            || (!isEditingSearch && routeResults != nil)
    }

    private func drawerCloseButton(_ title: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(title, systemImage: "xmark", action: action)
            .labelStyle(.iconOnly)
            .buttonStyle(.plain)
            .layoutPriority(1)
    }

    private func preferenceRow(
        title: LocalizedStringKey,
        value: LocalizedStringKey,
        systemImage: String
    ) -> some View {
        Button {} label: {
            HStack(spacing: 12) {
                Label(title, systemImage: systemImage)
                    .foregroundStyle(.primary)
                Spacer()
                Text(value)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func resultsList(includesStopWindow: Bool) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                resultsTabs

                switch resultsTab {
                case .results:
                    if includesStopWindow {
                        DisclosureGroup(isExpanded: $isResultsStopWindowExpanded) {
                            Text("Results prioritize chargers within the currently selected 100–150 mile window.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 8)
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Target Stop Window").font(.headline)
                                Text(routeResults?.windowDescription ?? "100–150 miles applied")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(14)
                        .background(.background.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
                    }

                    if isSearching { ProgressView("Finding chargers…") }
                    if let message { Text(message).font(.subheadline).foregroundStyle(.secondary) }
                    ForEach(chargers) { charger in
                        let stop = routeResults?.stops.first(where: { $0.id == charger.id })
                        ChargingResultCard(
                            name: charger.name,
                            address: charger.address,
                            arrival: stop.map { "\(Int($0.arrivalMinutes.rounded())) min ahead" } ?? "Nearby",
                            detour: stop.map { "+\(Int($0.detourMinutes.rounded(.up))) min detour" } ?? "In this area",
                            foodSummary: "Select to find restaurants within your walking preference",
                            connectorSummary: charger.metadataSummary ?? "Charging details unavailable",
                            isSaved: isSaved(charger),
                            action: { select(charger) }
                        )
                    }
                    if let notice = routeResults?.notice {
                        Text(notice).font(.caption).foregroundStyle(.secondary)
                    }
                case .restaurants:
                    SearchPreferenceSections(maximumWalkingMinutes: maximumWalkingMinutes)
                case .charging:
                    chargingPreferencesCard
                }
            }
            .padding()
        }
    }

    private var resultsTabs: some View {
        HStack(spacing: 8) {
            ForEach(ResultsTab.allCases) { tab in
                Button {
                    withAnimation(.snappy) { resultsTab = tab }
                } label: {
                    Image(systemName: tab.systemImage)
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(resultsTab == tab ? .white : .primary)
                .background(resultsTab == tab ? Color.blue : Color.clear, in: Capsule())
                .accessibilityLabel(tab.accessibilityTitle)
                .accessibilityAddTraits(resultsTab == tab ? .isSelected : [])
            }
        }
        .padding(5)
        .background(.secondary.opacity(0.12), in: Capsule())
    }

    private var chargingPreferencesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Charging needs").font(.headline).padding(.bottom, 8)
            preferenceRow(title: "Connector", value: "All", systemImage: "powerplug")
            Divider()
            preferenceRow(title: "Network", value: "All", systemImage: "network")
            Divider()
            preferenceRow(title: "Speed", value: "150+ kW", systemImage: "bolt.fill")
        }
        .padding(14)
        .background(.background.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
    }

    private func beginPlaceSearch() {
        destinationSelectionTask?.cancel()
        selectedDestinationPlace = nil
        selectedDestinationSubtitle = nil
        destination = ""
        showsNearbyResults = false
        isPlaceSearchPresented = true
        panelSize = .expanded
        locationCompleter.clear()
    }

    private func cancelPlaceSearch() {
        destinationSelectionTask?.cancel()
        isPlaceSearchPresented = false
        destination = ""
        locationCompleter.clear()
        panelSize = .compact
    }

    private func selectLocationSuggestion(_ suggestion: LocationSearchSuggestion) {
        destinationSelectionTask?.cancel()
        destinationSelectionTask = Task {
            do {
                guard let place = try await searchService.resolveDestination(suggestion.query) else {
                    message = "We couldn’t find that destination."
                    return
                }
                try Task.checkCancellation()
                destination = suggestion.title
                selectedDestinationSubtitle = suggestion.subtitle.isEmpty ? nil : suggestion.subtitle
                selectedDestinationPlace = place
                isPlaceSearchPresented = false
                locationCompleter.clear()
                panelSize = .expanded
                suppressesNextCameraPrompt = true
                cameraPosition = .region(MKCoordinateRegion(
                    center: place.mapItem.location.coordinate,
                    latitudinalMeters: 10_000,
                    longitudinalMeters: 10_000
                ))
            } catch is CancellationError {
                return
            } catch {
                message = searchMessage(for: error)
            }
        }
    }

    private func clearSelectedDestination() {
        selectedDestinationPlace = nil
        selectedDestinationSubtitle = nil
        destination = ""
        showsNearbyResults = false
        hasSearched = false
        panelSize = .compact
    }

    private func distanceDescription(to place: SearchPlace) -> String {
        guard let location = locationService.location else {
            return "Distance from current location unavailable"
        }
        let miles = location.distance(from: place.mapItem.location) / 1_609.344
        return "\(Int(miles.rounded()).formatted()) miles away"
    }

    private func startRouteToSelectedDestination() {
        routeDestination = destination
        showsNearbyResults = false
        searchMode = .route
        hasSearched = true
        isEditingSearch = true
        panelSize = .expanded
    }

    private func closeRoutePlanning() {
        cancelActiveSearches()
        routeResults = nil
        chargers = []
        selectedCharger = nil
        showsNearbyResults = false
        isEditingSearch = true
        searchMode = .nearby
        hasSearched = false
        panelSize = selectedDestinationPlace == nil ? .compact : .expanded
    }

    private func closeResults() {
        cancelActiveSearches()
        chargers = []
        selectedCharger = nil
        routeResults = nil
        message = nil
        resultsTab = .results
        isResultsStopWindowExpanded = false
        showsNearbyResults = false
        hasSearched = false
        isEditingSearch = true
        searchMode = .nearby
        if selectedDestinationPlace == nil {
            destination = ""
            panelSize = .compact
        } else {
            panelSize = .expanded
        }
    }

    private func closeNearbyResults() {
        cancelActiveSearches()
        chargers = []
        selectedCharger = nil
        message = nil
        resultsTab = .results
        showsNearbyResults = false
        isSearching = false
        isEditingSearch = true
        searchMode = .nearby
        hasSearched = false
        panelSize = selectedDestinationPlace == nil ? .compact : .expanded
    }

    private func searchNearbySelectedDestination() {
        searchMode = .nearby
        showsNearbyResults = true
        searchAroundSelectedDestination()
    }

    private func searchAroundSelectedDestination() {
        guard let selectedDestinationPlace else {
            search()
            return
        }

        let areaName = destination.trimmingCharacters(in: .whitespacesAndNewlines)
        let region = MKCoordinateRegion(
            center: selectedDestinationPlace.mapItem.location.coordinate,
            latitudinalMeters: 10_000,
            longitudinalMeters: 10_000
        )
        beginNearbySearch(in: region, areaName: areaName.isEmpty ? "this place" : areaName)
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
        showsNearbyResults = false
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
        if trimmedDestination.isEmpty || trimmedDestination.localizedCaseInsensitiveCompare("My location") == .orderedSame {
            searchesAfterLocationRequest = true
            waitingForNearbyLocation = true
            locationService.requestCurrentLocation()
            return
        }

        beginNearbySearch(in: nil, areaName: trimmedDestination)
    }

    private func searchVisibleRegion() {
        guard let visibleRegion else { return }
        searchMode = .nearby
        showsNearbyResults = true
        beginNearbySearch(in: visibleRegion, areaName: "this area")
    }

    private func beginNearbySearch(in region: MKCoordinateRegion?, areaName: String) {
        cancelActiveSearches()
        resultAreaName = areaName
        resultsTab = .results
        isResultsStopWindowExpanded = false
        searchMode = .nearby
        showsNearbyResults = true
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
        showsSearchHere = false

        areaSearchTask = Task {
            do {
                let searchRegion: MKCoordinateRegion
                if let region {
                    searchRegion = region
                } else {
                    guard let place = try await searchService.resolveDestination(areaName) else {
                        message = "We couldn’t find that destination."
                        isSearching = false
                        return
                    }
                    searchRegion = MKCoordinateRegion(
                        center: place.mapItem.location.coordinate,
                        latitudinalMeters: 10_000,
                        longitudinalMeters: 10_000
                    )
                }

                suppressesNextCameraPrompt = true
                withAnimation(.easeInOut(duration: 0.45)) {
                    cameraPosition = .region(searchRegion)
                }
                try Task.checkCancellation()
                await loadChargers(in: searchRegion, areaName: areaName)
            } catch is CancellationError {
                return
            } catch {
                message = searchMessage(for: error)
            }

            isSearching = false
        }
    }

    private func moveMapToCurrentLocation() {
        guard let location = locationService.location else { return }

        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 10_000,
            longitudinalMeters: 10_000
        )
        searchMode = .nearby
        suppressesNextCameraPrompt = true
        withAnimation(.easeInOut(duration: 0.45)) {
            cameraPosition = .region(region)
        }
        showsSearchHere = true
    }

    private func centerOnCurrentLocation() {
        guard let location = locationService.location else { return }
        resultAreaName = "your location"
        searchMode = .nearby
        showsNearbyResults = true
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
