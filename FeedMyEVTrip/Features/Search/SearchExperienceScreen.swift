import MapKit
import SwiftUI

struct SearchExperienceScreen: View {
    let state: SearchExperiencePreviewState
    @State private var selectedDestination: SearchExperiencePreviewState.Suggestion?

    init(state: SearchExperiencePreviewState) {
        self.state = state
        _selectedDestination = State(
            initialValue: state.phase == .destinationSelected ? state.suggestions.first : nil
        )
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                SearchExperienceMap(
                    state: state.mapState,
                    showsStartingSearch: false,
                    suggestions: state.suggestions,
                    topSafeAreaInset: geometry.safeAreaInsets.top,
                    onSelectDestination: { selectedDestination = $0 }
                )
                .ignoresSafeArea(edges: .top)

                SearchExperiencePanel(
                    state: state,
                    selectedDestination: selectedDestination,
                    onClearDestination: { selectedDestination = nil }
                )
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

struct SearchExperiencePreviewState {
    enum Phase {
        case starting
        case destinationSelected
        case navigationReady
        case chargerResults
        case restaurantPreferences
        case placeSearch
        case destinationEntry
        case journeyReady
        case namedArea
        case searching
        case results
        case empty
        case failure
    }

    struct Suggestion: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let systemImage: String
    }

    struct Result: Identifiable {
        let id: String
        let name: String
        let address: String
        let arrival: String
        let detour: String
        let foodSummary: String
        let connectorSummary: String
        let isSaved: Bool
        let coordinate: CLLocationCoordinate2D
    }

    struct MapState {
        let region: MKCoordinateRegion
        let route: [CLLocationCoordinate2D]
        let results: [Result]
        let selectedResultID: String?
        let showsRoute: Bool
        let showsSearchHere: Bool
    }

    let phase: Phase
    let destinationText: String
    let destinationDetail: String?
    let suggestions: [Suggestion]
    let originText: String
    let stopIntentTitle: String?
    let stopIntentSummary: String?
    let namedAreaText: String?
    let progressText: String?
    let message: String?
    let results: [Result]
    let mapState: MapState

    var showsJourneySummary: Bool {
        phase != .starting
            && phase != .destinationSelected
            && phase != .navigationReady
            && phase != .chargerResults
            && phase != .restaurantPreferences
            && phase != .placeSearch
            && phase != .destinationEntry
            && phase != .searching
            && phase != .empty
            && phase != .failure
    }
}

private struct SearchExperienceMap: View {
    let state: SearchExperiencePreviewState.MapState
    let showsStartingSearch: Bool
    let suggestions: [SearchExperiencePreviewState.Suggestion]
    let topSafeAreaInset: CGFloat
    let onSelectDestination: (SearchExperiencePreviewState.Suggestion) -> Void
    @State private var cameraPosition: MapCameraPosition
    @State private var showsSearchHere: Bool
    @State private var searchText = ""

    init(
        state: SearchExperiencePreviewState.MapState,
        showsStartingSearch: Bool,
        suggestions: [SearchExperiencePreviewState.Suggestion],
        topSafeAreaInset: CGFloat,
        onSelectDestination: @escaping (SearchExperiencePreviewState.Suggestion) -> Void
    ) {
        self.state = state
        self.showsStartingSearch = showsStartingSearch
        self.suggestions = suggestions
        self.topSafeAreaInset = topSafeAreaInset
        self.onSelectDestination = onSelectDestination
        _cameraPosition = State(initialValue: .region(state.region))
        _showsSearchHere = State(initialValue: state.showsSearchHere)
    }

    var body: some View {
        Map(position: $cameraPosition) {
            if state.showsRoute {
                MapPolyline(coordinates: state.route)
                    .stroke(.blue.opacity(0.7), lineWidth: 5)

                if let start = state.route.first {
                    Annotation("Route start", coordinate: start) {
                        Image(systemName: "circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                            .padding(4)
                            .background(.white, in: Circle())
                            .shadow(radius: 2)
                            .accessibilityLabel("My location")
                    }
                }

                if let destination = state.route.last {
                    Annotation("Destination", coordinate: destination) {
                        Image(systemName: "circle.fill")
                            .font(.title2)
                            .foregroundStyle(.red)
                            .padding(4)
                            .background(.white, in: Circle())
                            .shadow(radius: 2)
                            .accessibilityLabel("Destination")
                    }
                }
            }

            ForEach(state.results) { result in
                Annotation(result.name, coordinate: result.coordinate) {
                    SearchExperienceMapMarker(
                        isSaved: result.isSaved,
                        isSelected: result.id == state.selectedResultID
                    )
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .simultaneousGesture(
            DragGesture(minimumDistance: 8)
                .onChanged { _ in
                    showsSearchHere = true
                }
        )
        .overlay(alignment: .bottomTrailing) {
            Button {
                showsSearchHere = false
                cameraPosition = .userLocation(
                    fallback: .region(state.region)
                )
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
            .padding(.bottom, 130)
            .accessibilityLabel("Go to current location")
        }
        .overlay(alignment: .top) {
            VStack(spacing: 12) {
                if showsStartingSearch {
                    VStack(spacing: 0) {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            TextField("Search here", text: $searchText)
                                .textInputAutocapitalization(.words)
                                .submitLabel(.search)
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 50)

                        if !searchText.isEmpty {
                            Divider()
                            VStack(spacing: 0) {
                                ForEach(matchingSuggestions) { suggestion in
                                    Button {
                                        searchText = suggestion.title
                                        onSelectDestination(suggestion)
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: suggestion.systemImage)
                                                .foregroundStyle(.blue)
                                                .frame(width: 24)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(suggestion.title)
                                                    .foregroundStyle(.primary)
                                                Text(suggestion.subtitle)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                        }
                                        .padding(12)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 15))
                    .shadow(color: .black.opacity(0.14), radius: 8, y: 3)
                    .padding(.horizontal, 16)
                }

                if showsSearchHere {
                    Button("Search here") {
                        showsSearchHere = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.top, topSafeAreaInset + 12)
        }
    }

    private var matchingSuggestions: [SearchExperiencePreviewState.Suggestion] {
        suggestions.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.subtitle.localizedCaseInsensitiveContains(searchText)
        }
    }
}

private struct SearchExperienceMapMarker: View {
    let isSaved: Bool
    let isSelected: Bool

    var body: some View {
        Image(systemName: isSaved ? "bookmark.circle.fill" : "bolt.circle.fill")
            .font(isSelected ? .largeTitle : .title2)
            .symbolRenderingMode(.palette)
            .foregroundStyle(.white, isSaved ? .purple : .green)
            .padding(3)
            .background(.black.opacity(0.72), in: Circle())
            .shadow(radius: isSelected ? 5 : 2)
            .accessibilityHidden(true)
    }
}

private struct SearchExperiencePanel: View {
    private enum DrawerHeight {
        case compact
        case medium
        case expanded
    }

    let state: SearchExperiencePreviewState
    let selectedDestination: SearchExperiencePreviewState.Suggestion?
    let onClearDestination: () -> Void
    @State private var isStartingPanelExpanded = false
    @State private var startingSearchText = "My location"
    @State private var drawerHeight = DrawerHeight.medium

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(.secondary.opacity(0.45))
                .frame(width: 42, height: 5)
                .padding(.top, 9)
                .padding(.bottom, 10)

            if state.phase == .starting && selectedDestination == nil {
                    HStack(spacing: 10) {
                        HStack(spacing: 9) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            TextField("Search here", text: $startingSearchText)
                                .textInputAutocapitalization(.words)
                                .submitLabel(.search)
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 44)
                        .background(.background.opacity(0.88), in: RoundedRectangle(cornerRadius: 13))
                        .overlay {
                            RoundedRectangle(cornerRadius: 13)
                                .stroke(.secondary.opacity(0.2))
                        }

                        Button("Search") {}
                            .buttonStyle(.bordered)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            } else {
                SearchExperiencePanelHeader(
                    title: selectedDestination.map { LocalizedStringKey($0.title) } ?? panelTitle,
                    showsEdit: state.showsJourneySummary,
                    showsSearch: false,
                    showsClear: selectedDestination != nil
                        || state.phase == .navigationReady
                        || state.phase == .chargerResults
                        || state.phase == .searching
                        || state.phase == .empty
                        || state.phase == .failure,
                    onClear: onClearDestination
                )
            }

            if selectedDestination == nil {
                Divider()
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if state.showsJourneySummary {
                        JourneySummaryCard(
                            origin: state.originText,
                            destination: state.destinationText,
                            destinationDetail: state.destinationDetail
                        )
                    }

                    if let selectedDestination {
                        SelectedDestinationContent(
                            destination: selectedDestination,
                            distance: state.stopIntentSummary ?? "42 miles away",
                            driveTime: state.progressText ?? "52 min"
                        )
                    } else {
                    switch state.phase {
                    case .starting:
                        NearbyPreferencesContent()
                    case .destinationSelected:
                        EmptyView()
                    case .navigationReady:
                        NavigationRouteContent(
                            origin: state.originText,
                            destination: state.destinationText,
                            destinationDetail: state.destinationDetail,
                            results: state.results,
                            isSearching: false
                        )
                    case .chargerResults:
                        ChargerResultsTabs(results: state.results)
                    case .restaurantPreferences:
                        SelectedRestaurantPreferences()
                    case .placeSearch:
                        PlaceSearchContent()
                    case .destinationEntry:
                        DestinationEntryContent(state: state)
                    case .journeyReady:
                        StopIntentContent(state: state, showsNamedArea: false)
                    case .namedArea:
                        StopIntentContent(state: state, showsNamedArea: true)
                    case .searching:
                        NavigationRouteContent(
                            origin: state.originText,
                            destination: state.destinationText,
                            destinationDetail: state.destinationDetail,
                            results: state.results,
                            isSearching: true
                        )
                    case .results:
                        SearchResultsContent(results: state.results, message: state.message)
                    case .empty:
                        SearchMessageContent(
                            systemImage: "bolt.slash",
                            title: "No matching stops",
                            message: state.message ?? "Try a wider stop window or allow a longer detour.",
                            actionTitle: "Adjust search"
                        )
                    case .failure:
                        SearchMessageContent(
                            systemImage: "wifi.exclamationmark",
                            title: "Search couldn’t finish",
                            message: state.message ?? "Check your connection and try again.",
                            actionTitle: "Try again"
                        )
                    }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(maxHeight: panelMaximumHeight)
        .background(.regularMaterial)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 26, topTrailingRadius: 26))
        .shadow(color: .black.opacity(0.16), radius: 18, y: -4)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    withAnimation(.snappy) {
                        if state.phase == .starting, selectedDestination == nil {
                            if value.translation.height < -25 {
                                isStartingPanelExpanded = true
                            } else if value.translation.height > 25 {
                                isStartingPanelExpanded = false
                            }
                        } else if supportsDrawerDetents {
                            if value.translation.height < -25 {
                                drawerHeight = drawerHeight == .compact ? .medium : .expanded
                            } else if value.translation.height > 25 {
                                drawerHeight = drawerHeight == .expanded ? .medium : .compact
                            }
                        }
                    }
                }
        )
    }

    private var panelTitle: LocalizedStringKey {
        switch state.phase {
        case .starting:
            "Nearby"
        case .destinationSelected:
            "Destination"
        case .navigationReady:
            "Route"
        case .chargerResults:
            "Nearby Chargers"
        case .restaurantPreferences:
            "Restaurant Preferences"
        case .placeSearch:
            "Search"
        case .destinationEntry:
            "Plan a charging stop"
        case .journeyReady, .namedArea:
            "What kind of stop?"
        case .searching:
            "Searching your route"
        case .results:
            "Recommended stops"
        case .empty:
            "No stops found"
        case .failure:
            "Search unavailable"
        }
    }

    private var panelMaximumHeight: CGFloat {
        switch state.phase {
        case .starting:
            selectedDestination == nil ? (isStartingPanelExpanded ? 520 : 126) : 620
        case .destinationSelected:
            620
        case .navigationReady:
            interactiveDrawerHeight
        case .chargerResults:
            interactiveDrawerHeight
        case .restaurantPreferences:
            620
        case .placeSearch:
            720
        case .destinationEntry:
            520
        case .journeyReady, .namedArea:
            610
        case .searching:
            interactiveDrawerHeight
        case .results:
            interactiveDrawerHeight
        case .empty, .failure:
            interactiveDrawerHeight
        }
    }

    private var supportsDrawerDetents: Bool {
        switch state.phase {
        case .navigationReady, .chargerResults, .searching, .results, .empty, .failure:
            true
        default:
            false
        }
    }

    private var interactiveDrawerHeight: CGFloat {
        switch drawerHeight {
        case .compact: 126
        case .medium: 410
        case .expanded: 720
        }
    }
}

private struct PlaceSearchContent: View {
    @State private var searchText = ""

    private let recentSearches = [
        ("Richmond, VA", "Virginia, United States"),
        ("New Haven, CT", "Connecticut, United States"),
        ("New York, NY", "New York, United States"),
        ("Baltimore Inner Harbor", "Baltimore, Maryland"),
        ("Princeton, NJ", "New Jersey, United States"),
        ("Philadelphia, PA", "Pennsylvania, United States"),
        ("Washington, DC", "District of Columbia"),
        ("Wilmington, DE", "Delaware, United States"),
        ("Fredericksburg, VA", "Virginia, United States"),
        ("Trenton, NJ", "New Jersey, United States"),
        ("Annapolis, MD", "Maryland, United States"),
        ("Stamford, CT", "Connecticut, United States"),
        ("Atlantic City, NJ", "New Jersey, United States"),
        ("Arlington, VA", "Virginia, United States"),
        ("Harrisburg, PA", "Pennsylvania, United States"),
        ("Newark, DE", "Delaware, United States")
    ]

    private let restaurantSuggestions = [
        ("The Local Table", "American · 0.8 mi", "fork.knife"),
        ("Green Leaf Kitchen", "Healthy · 1.2 mi", "leaf.fill"),
        ("Taco Junction", "Mexican · 1.6 mi", "takeoutbag.and.cup.and.straw.fill")
    ]

    private let cuisines = ["American", "Italian", "Mexican", "Asian", "Indian", "Mediterranean"]

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search places", text: $searchText)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.search)
            }
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(.background.opacity(0.88), in: RoundedRectangle(cornerRadius: 15))
            .overlay {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(.secondary.opacity(0.2))
            }

            HStack(spacing: 12) {
                Button {} label: {
                    Label("Home", systemImage: "house.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {} label: {
                    Label("Add", systemImage: "plus")
                        .font(.headline)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Add a common location")
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Recents")
                    .font(.title2.bold())

                ScrollView(.horizontal) {
                    LazyHStack(alignment: .top, spacing: 12) {
                        ForEach(0..<4, id: \.self) { page in
                            LazyVStack(spacing: 0) {
                                ForEach(0..<4, id: \.self) { row in
                                    let recent = recentSearches[(page * 4) + row]
                                    Button {} label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: "clock.arrow.circlepath")
                                                .foregroundStyle(.secondary)
                                                .frame(width: 26)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(recent.0)
                                                    .font(.body.weight(.medium))
                                                    .foregroundStyle(.primary)
                                                Text(recent.1)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(1)
                                            }

                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.tertiary)
                                        }
                                        .padding(.vertical, 12)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)

                                    if row < 3 {
                                        Divider().padding(.leading, 38)
                                    }
                                }
                            }
                            .padding(.horizontal, 14)
                            .frame(width: 320)
                            .background(.background.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Restaurants")
                    .font(.title2.bold())

                ScrollView(.horizontal) {
                    LazyHStack(spacing: 12) {
                        ForEach(restaurantSuggestions, id: \.0) { restaurant in
                            Button {} label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    Image(systemName: restaurant.2)
                                        .font(.title2)
                                        .foregroundStyle(.orange)
                                    Text(restaurant.0)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(restaurant.1)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(width: 170, alignment: .leading)
                                .padding(14)
                                .background(.background.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Cuisines")
                    .font(.title2.bold())

                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(cuisines, id: \.self) { cuisine in
                            Button(cuisine) {}
                                .buttonStyle(.bordered)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}

private struct NavigationRouteContent: View {
    private enum RouteTab: String, CaseIterable, Identifiable {
        case driving
        case restaurants
        case charging

        var id: Self { self }

        var systemImage: String {
            switch self {
            case .driving: "car.fill"
            case .restaurants: "fork.knife"
            case .charging: "bolt.fill"
            }
        }

        var accessibilityTitle: LocalizedStringKey {
            switch self {
            case .driving: "Driving"
            case .restaurants: "Restaurant preferences"
            case .charging: "Charging needs"
            }
        }
    }

    private enum RangeUnit: String, CaseIterable {
        case miles = "Miles"
        case hours = "Hours"
    }

    let origin: String
    let destination: String
    let destinationDetail: String?
    let results: [SearchExperiencePreviewState.Result]
    let isSearching: Bool
    @State private var selectedTab = RouteTab.driving
    @State private var rangeUnit = RangeUnit.miles
    @State private var rangeStart = 100.0
    @State private var rangeEnd = 150.0
    @State private var walkingMinutes = 10
    @State private var isStopWindowExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            routeTabs

            switch selectedTab {
            case .driving:
                drivingContent
            case .restaurants:
                VStack(spacing: 14) {
                    preferenceCard(
                        title: "Restaurant preferences",
                        rows: [("Cuisine", "All"), ("Restaurants", "All")]
                    )
                    walkingContent
                }
            case .charging:
                preferenceCard(
                    title: "Charging needs",
                    rows: [("Connector", "All"), ("Network", "All"), ("Speed", "150+ kW")]
                )
            }
        }
    }

    private var routeTabs: some View {
        HStack(spacing: 8) {
            ForEach(RouteTab.allCases) { tab in
                Button {
                    withAnimation(.snappy) { selectedTab = tab }
                } label: {
                    Image(systemName: tab.systemImage)
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(selectedTab == tab ? .white : .primary)
                .background(selectedTab == tab ? Color.blue : Color.clear, in: Capsule())
                .accessibilityLabel(tab.accessibilityTitle)
                .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
            }
        }
        .padding(5)
        .background(.secondary.opacity(0.12), in: Capsule())
    }

    private var drivingContent: some View {
        VStack(spacing: 14) {
            VStack(spacing: 10) {
                routeField(
                    title: origin,
                    detail: nil,
                    color: origin.localizedCaseInsensitiveCompare("My location") == .orderedSame ? .blue : .green,
                    accessibilityLabel: "Route start"
                )

                routeField(
                    title: destination,
                    detail: destinationDetail,
                    color: .red,
                    accessibilityLabel: "Route destination"
                )
            }

            DisclosureGroup(isExpanded: $isStopWindowExpanded) {
                VStack(alignment: .leading, spacing: 14) {
                    Picker("Range unit", selection: $rangeUnit) {
                        ForEach(RangeUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: rangeUnit) { _, unit in
                        switch unit {
                        case .miles:
                            rangeStart = 100
                            rangeEnd = 150
                        case .hours:
                            rangeStart = 1.5
                            rangeEnd = 2.5
                        }
                    }

                    rangeRow(title: "From", value: $rangeStart)
                    rangeRow(title: "To", value: $rangeEnd)
                }
                .padding(.top, 12)
            } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Target Stop Window")
                        .font(.headline)
                    Text(stopWindowSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .background(.background.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))

            if !results.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Charging stops")
                        .font(.headline)
                    ForEach(results.prefix(3)) { result in
                        ChargerResultPreviewRow(result: result)
                    }
                }
            }

            if isSearching {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Finding compatible charging stops…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(.background.opacity(0.82), in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var walkingContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How far are you willing to walk?")
                .font(.headline)
            Picker("Maximum walking time", selection: $walkingMinutes) {
                ForEach([5, 10, 15, 20], id: \.self) { minutes in
                    Text("\(minutes) min").tag(minutes)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(14)
        .background(.background.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
    }

    private func rangeRow(title: LocalizedStringKey, value: Binding<Double>) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .frame(width: 48, alignment: .leading)

            Button {
                value.wrappedValue = max(0, value.wrappedValue - rangeIncrement)
            } label: {
                Image(systemName: "minus")
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Decrease value")

            Text(formattedRangeValue(value.wrappedValue))
                .monospacedDigit()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

            Button {
                value.wrappedValue += rangeIncrement
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Increase value")
        }
    }

    private var rangeIncrement: Double {
        rangeUnit == .miles ? 25 : 0.5
    }

    private var stopWindowSummary: String {
        "\(formattedRangeValue(rangeStart))–\(formattedRangeValue(rangeEnd)) \(rangeUnit.rawValue.lowercased()) applied"
    }

    private func formattedRangeValue(_ value: Double) -> String {
        value.formatted(
            .number.precision(.fractionLength(rangeUnit == .miles ? 0 : 1))
        )
    }

    private func preferenceCard(
        title: LocalizedStringKey,
        rows: [(LocalizedStringKey, LocalizedStringKey)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 8)

            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                Button {} label: {
                    HStack {
                        Text(row.0)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(row.1)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if index < rows.count - 1 {
                    Divider()
                }
            }
        }
        .padding(14)
        .background(.background.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
    }

    private func routeField(
        title: String,
        detail: String?,
        color: Color,
        accessibilityLabel: LocalizedStringKey
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "circle.fill")
                .foregroundStyle(color)
                .accessibilityLabel(accessibilityLabel)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(.background.opacity(0.86), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.secondary.opacity(0.2))
        }
    }
}

private struct NearbyPreferencesContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            preferenceSection(
                title: "Restaurant preferences",
                rows: [
                    ("Cuisine", "All", "fork.knife"),
                    ("Restaurants", "All", "building.2"),
                    ("Maximum walk", "10 minutes", "figure.walk")
                ]
            )

            preferenceSection(
                title: "Charging needs",
                rows: [
                    ("Connector", "All", "powerplug"),
                    ("Network", "All", "network"),
                    ("Speed", "150+ kW", "bolt.fill")
                ]
            )
        }
    }

    private func preferenceSection(
        title: LocalizedStringKey,
        rows: [(LocalizedStringKey, LocalizedStringKey, String)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 8)

            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                Button {} label: {
                    HStack(spacing: 12) {
                        Label(row.0, systemImage: row.2)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(row.1)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if index < rows.count - 1 {
                    Divider().padding(.leading, 32)
                }
            }
        }
        .padding(14)
        .background(.background.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct SearchExperiencePanelHeader: View {
    let title: LocalizedStringKey
    let showsEdit: Bool
    let showsSearch: Bool
    let showsClear: Bool
    let onClear: () -> Void

    var body: some View {
        Group {
            if showsClear {
                ZStack {
                    Text(title)
                        .font(.title3.bold())

                    HStack {
                        Spacer()
                        Button("Clear destination", systemImage: "xmark") {
                            onClear()
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear destination")
                    }
                }
            } else {
                HStack {
                    Text(title)
                        .font(.title3.bold())

                    Spacer()

                    if showsSearch {
                        Button("Search") {}
                            .buttonStyle(.bordered)
                    } else if showsEdit {
                        Button("Edit journey") {}
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
}

private struct SelectedDestinationContent: View {
    let destination: SearchExperiencePreviewState.Suggestion
    let distance: String
    let driveTime: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(distance)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button {} label: {
                    Label(driveTime, systemImage: "car.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button("Nearby Chargers") {}
                    .buttonStyle(.bordered)
            }

            TargetStopWindowSummary()
            NearbyPreferencesContent()
        }
    }
}

private struct TargetStopWindowSummary: View {
    private enum Unit: String, CaseIterable {
        case miles = "Miles"
        case hours = "Hours"
    }

    @State private var isExpanded = false
    @State private var unit = Unit.miles
    @State private var start = 100.0
    @State private var end = 150.0

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(spacing: 14) {
                Picker("Range unit", selection: $unit) {
                    ForEach(Unit.allCases, id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: unit) { _, newUnit in
                    if newUnit == .miles {
                        start = 100
                        end = 150
                    } else {
                        start = 1.5
                        end = 2.5
                    }
                }

                valueRow("From", value: $start)
                valueRow("To", value: $end)
            }
            .padding(.top, 12)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Target Stop Window")
                    .font(.headline)
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(.background.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
    }

    private func valueRow(_ title: LocalizedStringKey, value: Binding<Double>) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .frame(width: 48, alignment: .leading)
            Button {
                value.wrappedValue = max(0, value.wrappedValue - increment)
            } label: {
                Image(systemName: "minus")
            }
            .buttonStyle(.bordered)

            Text(formatted(value.wrappedValue))
                .monospacedDigit()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

            Button {
                value.wrappedValue += increment
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.bordered)
        }
    }

    private var increment: Double { unit == .miles ? 25 : 0.5 }

    private var summary: String {
        "\(formatted(start))–\(formatted(end)) \(unit.rawValue.lowercased()) applied"
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(unit == .miles ? 0 : 1)))
    }
}

private struct ChargerResultPreviewRow: View {
    let result: SearchExperiencePreviewState.Result

    var body: some View {
        ChargingResultCard(result: result)
    }
}

private struct ChargerResultsTabs: View {
    private enum Tab: String, CaseIterable, Identifiable {
        case results, restaurants, charging
        var id: Self { self }
        var image: String {
            switch self {
            case .results: "list.bullet.circle.fill"
            case .restaurants: "fork.knife"
            case .charging: "bolt.fill"
            }
        }
    }

    let results: [SearchExperiencePreviewState.Result]
    @State private var selectedTab = Tab.results

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                ForEach(Tab.allCases) { tab in
                    Button {
                        withAnimation(.snappy) { selectedTab = tab }
                    } label: {
                        Image(systemName: tab.image)
                            .font(.title3)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(selectedTab == tab ? .white : .primary)
                    .background(selectedTab == tab ? Color.blue : Color.clear, in: Capsule())
                    .accessibilityLabel(tab.rawValue.capitalized)
                }
            }
            .padding(5)
            .background(.secondary.opacity(0.12), in: Capsule())

            switch selectedTab {
            case .results:
                ForEach(results) { result in
                    ChargerResultPreviewRow(result: result)
                }
            case .restaurants:
                simplePreferences(
                    "Restaurant preferences",
                    rows: ["Cuisine · All", "Restaurants · All", "Maximum walk · 10 minutes"]
                )
            case .charging:
                simplePreferences("Charging needs", rows: ["Connector · All", "Network · All", "Speed · 150+ kW"])
            }
        }
    }

    private func simplePreferences(_ title: LocalizedStringKey, rows: [LocalizedStringKey]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack {
                    Text(row)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(14)
        .background(.background.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct SelectedRestaurantPreferences: View {
    @State private var walkingMinutes = 10

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            preferenceSection(
                title: "Cuisines",
                rows: [
                    ("Italian", "Selected"),
                    ("Mexican", "Selected")
                ]
            )

            preferenceSection(
                title: "Restaurants",
                rows: [
                    ("Chipotle", "Selected"),
                    ("Panera Bread", "Selected"),
                    ("+3 more", "")
                ]
            )

            VStack(alignment: .leading, spacing: 12) {
                Text("Maximum walking time")
                    .font(.headline)
                Picker("Maximum walking time", selection: $walkingMinutes) {
                    ForEach([5, 10, 15, 20], id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(14)
            .background(.background.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private func preferenceSection(
        title: LocalizedStringKey,
        rows: [(LocalizedStringKey, LocalizedStringKey)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 8)

            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                HStack {
                    Text(row.0)
                    Spacer()
                    Text(row.1)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if index < 2 {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                    }
                }
                .padding(.vertical, 11)

                if index < rows.count - 1 {
                    Divider()
                }
            }
        }
        .padding(14)
        .background(.background.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct DestinationEntryContent: View {
    let state: SearchExperiencePreviewState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Where are you headed?")
                    .font(.title2.bold())
                Text("Start with your destination. We’ll use your current location unless you choose another starting point.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            SearchFieldPreview(
                label: "Destination",
                text: state.destinationText,
                systemImage: "flag.checkered",
                isFocused: true
            )

            if !state.suggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(state.suggestions) { suggestion in
                        SearchSuggestionRow(suggestion: suggestion)
                        if suggestion.id != state.suggestions.last?.id {
                            Divider().padding(.leading, 44)
                        }
                    }
                }
                .background(.background.opacity(0.82), in: RoundedRectangle(cornerRadius: 14))
            }

            Button {} label: {
                Label("Continue", systemImage: "arrow.right")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(state.destinationDetail == nil)
        }
    }
}

private struct SearchFieldPreview: View {
    let label: LocalizedStringKey
    let text: String
    let systemImage: String
    let isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(isFocused ? .blue : .secondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(text.isEmpty ? "Search for a place" : text)
                    .foregroundStyle(text.isEmpty ? .tertiary : .primary)
            }

            Spacer()

            if !text.isEmpty {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(13)
        .background(.background.opacity(0.88), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(isFocused ? .blue : .secondary.opacity(0.25), lineWidth: isFocused ? 2 : 1)
        }
    }
}

private struct SearchSuggestionRow: View {
    let suggestion: SearchExperiencePreviewState.Suggestion

    var body: some View {
        Button {} label: {
            HStack(spacing: 12) {
                Image(systemName: suggestion.systemImage)
                    .foregroundStyle(.blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(suggestion.title)
                        .font(.body.weight(.medium))
                    Text(suggestion.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct JourneySummaryCard: View {
    let origin: String
    let destination: String
    let destinationDetail: String?

    var body: some View {
        VStack(spacing: 10) {
            JourneySummaryRow(
                systemImage: "location.fill",
                tint: .blue,
                label: "From",
                primaryText: origin,
                secondaryText: nil
            )

            HStack {
                Rectangle()
                    .fill(.secondary.opacity(0.25))
                    .frame(width: 2, height: 18)
                    .padding(.leading, 10)
                Spacer()
            }

            JourneySummaryRow(
                systemImage: "flag.checkered",
                tint: .red,
                label: "To",
                primaryText: destination,
                secondaryText: destinationDetail
            )
        }
        .padding(14)
        .background(.background.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct JourneySummaryRow: View {
    let systemImage: String
    let tint: Color
    let label: LocalizedStringKey
    let primaryText: String
    let secondaryText: String?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(primaryText)
                    .font(.body.weight(.semibold))
                if let secondaryText {
                    Text(secondaryText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }
}

private struct StopIntentContent: View {
    let state: SearchExperiencePreviewState
    let showsNamedArea: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How do you want to choose your stop?")
                .font(.headline)

            StopIntentCard(
                systemImage: "road.lanes",
                title: "Find a stop ahead",
                detail: "Choose a driving-time or distance window.",
                isSelected: !showsNamedArea
            )

            StopIntentCard(
                systemImage: "mappin.and.ellipse",
                title: "Stop near a place",
                detail: "Focus on a town, interchange, or neighborhood.",
                isSelected: showsNamedArea
            )

            if showsNamedArea {
                SearchFieldPreview(
                    label: "Stopping area",
                    text: state.namedAreaText ?? "",
                    systemImage: "mappin",
                    isFocused: true
                )
                Text("We’ll compare compatible chargers within 10 km and keep the active route and detour in context.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                StopWindowPreview()
            }

            DisclosureGroup("More options") {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Maximum detour: 20 minutes", systemImage: "arrow.triangle.branch")
                    Label("Connector preferences applied", systemImage: "bolt.badge.checkmark")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            }

            Button {} label: {
                Label("Find charging stops", systemImage: "magnifyingglass")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

private struct StopIntentCard: View {
    let systemImage: String
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
    let isSelected: Bool

    var body: some View {
        Button {} label: {
            HStack(spacing: 13) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : .blue)
                    .frame(width: 38, height: 38)
                    .background(isSelected ? Color.blue : Color.blue.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.body.weight(.semibold))
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.blue : Color.secondary.opacity(0.45))
            }
            .padding(13)
            .background(.background.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? .blue : .secondary.opacity(0.18), lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct StopWindowPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Measure ahead in", selection: .constant("Minutes")) {
                Text("Minutes").tag("Minutes")
                Text("Miles").tag("Miles")
            }
            .pickerStyle(.segmented)

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Stop window")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("60–120 minutes ahead")
                        .font(.body.weight(.semibold))
                }

                Spacer()

                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(.blue)
            }
        }
        .padding(14)
        .background(.background.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct SearchingContent: View {
    let message: String

    var body: some View {
        VStack(spacing: 18) {
            ProgressView()
                .controlSize(.large)
            Text(message)
                .font(.headline)
            Text("Checking compatible chargers, arrival timing, and added detour.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Cancel search", role: .cancel) {}
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

private struct SearchResultsContent: View {
    let results: [SearchExperiencePreviewState.Result]
    let message: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(results) { result in
                ChargingResultCard(result: result)
            }

            Text("Driving estimates can change. Charger data is not live availability.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct SearchMessageContent: View {
    let systemImage: String
    let title: LocalizedStringKey
    let message: String
    let actionTitle: LocalizedStringKey

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title3.bold())
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(actionTitle) {}
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
