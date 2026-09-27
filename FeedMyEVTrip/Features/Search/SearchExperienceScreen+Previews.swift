import MapKit
import SwiftUI

#Preview("1 · Starting screen") {
    SearchExperienceScreen(state: .starting)
}

#Preview("2 · Search places") {
    SearchExperienceScreen(state: .placeSearch)
}

#Preview("3 · Destination selected") {
    SearchExperienceScreen(state: .destinationSelected)
}

#Preview("4 · Route to destination") {
    SearchExperienceScreen(state: .navigationReady)
}

#Preview("5 · Destination suggestions") {
    SearchExperienceScreen(state: .destinationSuggestions)
}

#Preview("6 · Choose stop intent") {
    SearchExperienceScreen(state: .journeyReady)
}

#Preview("7 · Named stopping area") {
    SearchExperienceScreen(state: .namedArea)
}

#Preview("8 · Searching") {
    SearchExperienceScreen(state: .searching)
}

#Preview("9 · Recommended stops") {
    SearchExperienceScreen(state: .results)
}

#Preview("10 · No matching stops") {
    SearchExperienceScreen(state: .empty)
}

#Preview("11 · Lookup failure") {
    SearchExperienceScreen(state: .failure)
}

#Preview("12 · Map moved") {
    SearchExperienceScreen(state: .mapMoved)
}

private extension SearchExperiencePreviewState {
    static let starting = SearchExperiencePreviewState(
        phase: .starting,
        destinationText: "",
        destinationDetail: nil,
        suggestions: .destinationSamples,
        originText: "Current location",
        stopIntentTitle: nil,
        stopIntentSummary: nil,
        namedAreaText: nil,
        progressText: nil,
        message: nil,
        results: [],
        mapState: .quiet
    )

    static let destinationSelected = SearchExperiencePreviewState(
        phase: .destinationSelected,
        destinationText: "Richmond",
        destinationDetail: "Richmond, VA, United States",
        suggestions: [Suggestion(
            id: "richmond-va",
            title: "Richmond, VA",
            subtitle: "Virginia, United States",
            systemImage: "building.2"
        )],
        originText: "Current location",
        stopIntentTitle: nil,
        stopIntentSummary: "286 miles away",
        namedAreaText: nil,
        progressText: "4 hr 18 min",
        message: nil,
        results: [],
        mapState: .quiet
    )

    static let navigationReady = SearchExperiencePreviewState(
        phase: .navigationReady,
        destinationText: "Richmond, VA",
        destinationDetail: "Virginia, United States",
        suggestions: [],
        originText: "My location",
        stopIntentTitle: nil,
        stopIntentSummary: "286 miles away",
        namedAreaText: nil,
        progressText: "4 hr 18 min",
        message: nil,
        results: [],
        mapState: .journey
    )

    static let placeSearch = SearchExperiencePreviewState(
        phase: .placeSearch,
        destinationText: "",
        destinationDetail: nil,
        suggestions: .destinationSamples,
        originText: "My location",
        stopIntentTitle: nil,
        stopIntentSummary: nil,
        namedAreaText: nil,
        progressText: nil,
        message: nil,
        results: [],
        mapState: .quiet
    )

    static let destinationSuggestions = SearchExperiencePreviewState(
        phase: .destinationEntry,
        destinationText: "Richmond",
        destinationDetail: nil,
        suggestions: [
            Suggestion(
                id: "richmond-va",
                title: "Richmond",
                subtitle: "Richmond, VA, United States",
                systemImage: "building.2"
            ),
            Suggestion(
                id: "richmond-highway",
                title: "Richmond Highway",
                subtitle: "Alexandria, VA, United States",
                systemImage: "road.lanes"
            ),
            Suggestion(
                id: "richmond-international",
                title: "Richmond International Airport",
                subtitle: "1 Richard E Byrd Terminal Drive, Richmond, VA",
                systemImage: "airplane"
            )
        ],
        originText: "Current location",
        stopIntentTitle: nil,
        stopIntentSummary: nil,
        namedAreaText: nil,
        progressText: nil,
        message: nil,
        results: [],
        mapState: .quiet
    )

    static let journeyReady = SearchExperiencePreviewState(
        phase: .journeyReady,
        destinationText: "Richmond",
        destinationDetail: "Richmond, VA, United States",
        suggestions: [],
        originText: "Current location · Pennington, NJ",
        stopIntentTitle: "Find a stop ahead",
        stopIntentSummary: "60–120 minutes ahead",
        namedAreaText: nil,
        progressText: nil,
        message: nil,
        results: [],
        mapState: .journey
    )

    static let namedArea = SearchExperiencePreviewState(
        phase: .namedArea,
        destinationText: "Richmond",
        destinationDetail: "Richmond, VA, United States",
        suggestions: [],
        originText: "Current location · Pennington, NJ",
        stopIntentTitle: "Stop near a place",
        stopIntentSummary: "Within 10 km",
        namedAreaText: "Baltimore Inner Harbor",
        progressText: nil,
        message: nil,
        results: [],
        mapState: .journey
    )

    static let searching = SearchExperiencePreviewState(
        phase: .searching,
        destinationText: "Richmond",
        destinationDetail: "Richmond, VA, United States",
        suggestions: [],
        originText: "Current location · Pennington, NJ",
        stopIntentTitle: "Find a stop ahead",
        stopIntentSummary: "60–120 minutes ahead · Maximum 20 minute detour",
        namedAreaText: nil,
        progressText: "Checking driving time 7 of 12…",
        message: nil,
        results: [],
        mapState: .journey
    )

    static let results = SearchExperiencePreviewState(
        phase: .results,
        destinationText: "Richmond",
        destinationDetail: "Richmond, VA, United States",
        suggestions: [],
        originText: "Current location · Pennington, NJ",
        stopIntentTitle: "Find a stop ahead",
        stopIntentSummary: "60–120 minutes ahead · Maximum 20 minute detour",
        namedAreaText: nil,
        progressText: nil,
        message: "Best matches for 60–120 minutes ahead, ordered by added detour.",
        results: .sampleResults,
        mapState: .results
    )

    static let empty = SearchExperiencePreviewState(
        phase: .empty,
        destinationText: "Richmond",
        destinationDetail: "Richmond, VA, United States",
        suggestions: [],
        originText: "Current location · Pennington, NJ",
        stopIntentTitle: "Find a stop ahead",
        stopIntentSummary: "60–90 minutes ahead · Maximum 10 minute detour",
        namedAreaText: nil,
        progressText: nil,
        message: "No compatible charging stops fit this window and detour limit. Try a wider window or allow a longer detour.",
        results: [],
        mapState: .journey
    )

    static let failure = SearchExperiencePreviewState(
        phase: .failure,
        destinationText: "Richmond",
        destinationDetail: "Richmond, VA, United States",
        suggestions: [],
        originText: "Current location · Pennington, NJ",
        stopIntentTitle: "Stop near a place",
        stopIntentSummary: "Baltimore Inner Harbor · Within 10 km",
        namedAreaText: "Baltimore Inner Harbor",
        progressText: nil,
        message: "Apple Maps couldn’t complete this search. Check your connection and try again without rebuilding your journey.",
        results: [],
        mapState: .journey
    )

    static let mapMoved = SearchExperiencePreviewState(
        phase: .results,
        destinationText: "Richmond",
        destinationDetail: "Richmond, VA, United States",
        suggestions: [],
        originText: "Current location · Pennington, NJ",
        stopIntentTitle: "Find a stop ahead",
        stopIntentSummary: "60–120 minutes ahead · Maximum 20 minute detour",
        namedAreaText: nil,
        progressText: nil,
        message: "Move the map to explore another area.",
        results: .sampleResults,
        mapState: .panned
    )
}

private extension Array where Element == SearchExperiencePreviewState.Suggestion {
    static let destinationSamples: [Element] = [
        Element(
            id: "richmond-va",
            title: "Richmond, VA",
            subtitle: "Virginia, United States",
            systemImage: "building.2"
        ),
        Element(
            id: "richmond-highway",
            title: "Richmond Highway",
            subtitle: "Alexandria, VA, United States",
            systemImage: "road.lanes"
        ),
        Element(
            id: "richmond-airport",
            title: "Richmond International Airport",
            subtitle: "1 Richard E Byrd Terminal Drive, Richmond, VA",
            systemImage: "airplane"
        )
    ]
}

private extension Array where Element == SearchExperiencePreviewState.Result {
    static let sampleResults: [Element] = [
        Element(
            id: "white-marsh",
            name: "White Marsh Mall Charging",
            address: "8200 Perry Hall Boulevard, Baltimore, MD",
            arrival: "1 hr 24 min ahead",
            detour: "+6 min detour",
            foodSummary: "4 food options within a 10 minute walk",
            connectorSummary: "CCS · NACS · 12 DC-fast ports",
            isSaved: true,
            coordinate: CLLocationCoordinate2D(latitude: 39.3748, longitude: -76.4632)
        ),
        Element(
            id: "canton",
            name: "Canton Crossing EV Station",
            address: "3800 Boston Street, Baltimore, MD",
            arrival: "1 hr 31 min ahead",
            detour: "+9 min detour",
            foodSummary: "Chipotle and 6 other nearby options",
            connectorSummary: "CCS · 8 DC-fast ports",
            isSaved: false,
            coordinate: CLLocationCoordinate2D(latitude: 39.2767, longitude: -76.5661)
        ),
        Element(
            id: "laurel",
            name: "Laurel Travel Plaza",
            address: "14800 Baltimore Avenue, Laurel, MD",
            arrival: "1 hr 46 min ahead",
            detour: "+12 min detour",
            foodSummary: "2 food options within a 15 minute walk",
            connectorSummary: "CCS · CHAdeMO · 6 DC-fast ports",
            isSaved: false,
            coordinate: CLLocationCoordinate2D(latitude: 39.0908, longitude: -76.8569)
        )
    ]
}

private extension SearchExperiencePreviewState.MapState {
    static let quiet = SearchExperiencePreviewState.MapState(
        region: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.8, longitude: -75.2),
            latitudinalMeters: 260_000,
            longitudinalMeters: 260_000
        ),
        route: [],
        results: [],
        selectedResultID: nil,
        showsRoute: false,
        showsSearchHere: false
    )

    static let journey = SearchExperiencePreviewState.MapState(
        region: routeRegion,
        route: routeCoordinates,
        results: [],
        selectedResultID: nil,
        showsRoute: true,
        showsSearchHere: false
    )

    static let results = SearchExperiencePreviewState.MapState(
        region: routeRegion,
        route: routeCoordinates,
        results: .sampleResults,
        selectedResultID: "white-marsh",
        showsRoute: true,
        showsSearchHere: false
    )

    static let panned = SearchExperiencePreviewState.MapState(
        region: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.45, longitude: -76.35),
            latitudinalMeters: 120_000,
            longitudinalMeters: 120_000
        ),
        route: routeCoordinates,
        results: .sampleResults,
        selectedResultID: nil,
        showsRoute: true,
        showsSearchHere: true
    )

    static let routeRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 38.9, longitude: -76.2),
        latitudinalMeters: 480_000,
        longitudinalMeters: 360_000
    )

    static let routeCoordinates = [
        CLLocationCoordinate2D(latitude: 40.329, longitude: -74.791),
        CLLocationCoordinate2D(latitude: 39.952, longitude: -75.165),
        CLLocationCoordinate2D(latitude: 39.290, longitude: -76.612),
        CLLocationCoordinate2D(latitude: 38.907, longitude: -77.037),
        CLLocationCoordinate2D(latitude: 37.541, longitude: -77.436)
    ]
}
