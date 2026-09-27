import MapKit
import Combine

struct RouteStop: Identifiable {
    var id: UUID { charger.id }
    let charger: ChargerResult
    let arrivalMinutes: Double
    let arrivalMiles: Double
    let detourMinutes: Double

    var summary: String {
        "\(Int(arrivalMinutes.rounded())) min ahead · \(Int(arrivalMiles.rounded())) mi · +\(Int(detourMinutes.rounded(.up))) min detour"
    }
}

struct RouteStopResults {
    let route: MKRoute
    let stopSegment: MKPolyline
    let windowDescription: String
    let stops: [RouteStop]
    let destinationName: String
    let startCoordinate: CLLocationCoordinate2D
    let destinationCoordinate: CLLocationCoordinate2D
    let notice: String?
}

enum StopWindowUnit: String, CaseIterable, Identifiable {
    case minutes = "Minutes", miles = "Miles"
    var id: String { rawValue }
}

struct StopWindow {
    let unit: StopWindowUnit
    let lower: Double
    let upper: Double

    func contains(minutes: Double, miles: Double) -> Bool {
        (lower...upper).contains(unit == .minutes ? minutes : miles)
    }
}

/// Distances along the road geometry, rather than distance from the route's origin.
struct RouteGeometry {
    let points: [MKMapPoint]
    let distances: [Double]
    var length: Double { distances.last ?? 0 }

    init(polyline: MKPolyline) {
        points = Array(UnsafeBufferPointer(start: polyline.points(), count: polyline.pointCount))
        var accumulated = [0.0]
        for index in 1..<max(1, points.count) {
            accumulated.append(accumulated.last! + points[index - 1].distance(to: points[index]))
        }
        distances = accumulated
    }

    func coordinate(at distance: Double) -> CLLocationCoordinate2D {
        guard let first = points.first else { return CLLocationCoordinate2D() }
        guard points.count > 1 else { return first.coordinate }
        let target = min(max(distance, 0), length)
        for index in 1..<points.count where distances[index] >= target {
            let span = distances[index] - distances[index - 1]
            let fraction = span > 0 ? (target - distances[index - 1]) / span : 0
            return MKMapPoint(
                x: points[index - 1].x + (points[index].x - points[index - 1].x) * fraction,
                y: points[index - 1].y + (points[index].y - points[index - 1].y) * fraction
            ).coordinate
        }
        return points.last!.coordinate
    }

    func projection(of coordinate: CLLocationCoordinate2D) -> (along: Double, offset: Double) {
        let point = MKMapPoint(coordinate)
        var best = (along: 0.0, offset: Double.infinity)
        guard points.count > 1 else { return best }
        for index in 1..<points.count {
            let a = points[index - 1], b = points[index]
            let dx = b.x - a.x, dy = b.y - a.y
            let squared = dx * dx + dy * dy
            let fraction = squared > 0 ? min(1, max(0, ((point.x - a.x) * dx + (point.y - a.y) * dy) / squared)) : 0
            let projected = MKMapPoint(x: a.x + dx * fraction, y: a.y + dy * fraction)
            let offset = point.distance(to: projected)
            if offset < best.offset {
                best = (distances[index - 1] + fraction * (distances[index] - distances[index - 1]), offset)
            }
        }
        return best
    }
}

@MainActor
final class RouteStopService: ObservableObject {
    @Published var progress = "Calculating route…"
    private let places = MapSearchService()
    private var activeDirections: MKDirections?

    func cancel() {
        places.cancelActiveSearch()
        activeDirections?.cancel()
        activeDirections = nil
    }

    func find(originQuery: String, location: CLLocation?, destinationQuery: String,
              window: StopWindow, maximumDetour: Double, savedChargers: [ChargerResult]) async throws -> RouteStopResults {
        progress = "Loading charger catalog…"
        let catalog = try await AFDCChargerProvider.shared.loadChargers()
        try Task.checkCancellation()
        progress = "Finding your route…"
        let origin: MKMapItem
        if originQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            guard let location else { throw RouteFailure.message("Use your location or enter a starting place.") }
            origin = MKMapItem(location: location, address: nil)
        } else {
            guard let found = try await places.resolveDestination(originQuery) else {
                throw RouteFailure.message("Couldn’t find your starting place.")
            }
            origin = found.mapItem
        }
        guard let destination = try await places.resolveDestination(destinationQuery) else {
            throw RouteFailure.message("Couldn’t find your destination.")
        }
        let route = try await drivingRoute(from: origin, to: destination.mapItem)
        let geometry = RouteGeometry(polyline: route.polyline)
        let total = window.unit == .minutes ? route.expectedTravelTime / 60 : route.distance / 1609.344
        guard total > window.lower, geometry.length > 0 else {
            throw RouteFailure.message("Your destination is before this stop window. Choose an earlier window.")
        }
        // Broad time-window sampling is approximate. Actual driving routes validate each result below.
        let lowerFraction = max(0, window.lower / total - (window.unit == .minutes ? 0.12 : 0.02))
        let upperFraction = min(1, window.upper / total + (window.unit == .minutes ? 0.12 : 0.02))
        let start = geometry.length * lowerFraction
        let end = geometry.length * upperFraction
        progress = "Finding chargers along your route…"
        let padding = 8_000 * MKMapPointsPerMeterAtLatitude(route.polyline.coordinate.latitude)
        let bounds = route.polyline.boundingMapRect.insetBy(dx: -padding, dy: -padding)
        let ranked = catalog.filter { bounds.contains(MKMapPoint($0.coordinate)) }
            .map { ($0, geometry.projection(of: $0.coordinate)) }
            .filter { $0.1.offset <= 8_000 && $0.1.along >= start && $0.1.along <= end }
            .sorted { $0.1.offset < $1.1.offset }.map { $0.0 }
        var failures = 0
        // Saved stops bypass the approximate corridor and discovery cap. Actual driving
        // routes below decide whether they meet the arrival window and detour limit.
        var savedCandidates: [ChargerResult] = []
        for saved in savedChargers {
            // Use the catalog's stable ID and current metadata for matching favorites.
            let charger = catalog.first(where: { $0.matches(saved) }) ?? saved
            if !savedCandidates.contains(where: { $0.matches(charger) }) { savedCandidates.append(charger) }
        }
        let unsavedCandidates = ranked.filter { candidate in
            !savedCandidates.contains { $0.matches(candidate) }
        }
        let checkedCandidates = savedCandidates + Array(unsavedCandidates.prefix(12))
        var stops: [RouteStop] = []
        for (index, charger) in checkedCandidates.enumerated() {
            try Task.checkCancellation()
            progress = "Checking driving time \(index + 1) of \(checkedCandidates.count)…"
            do {
                let first = try await drivingRoute(from: origin, to: charger.mapItem)
                let minutes = first.expectedTravelTime / 60
                let miles = first.distance / 1609.344
                guard window.contains(minutes: minutes, miles: miles) else { continue }
                let second = try await drivingRoute(from: charger.mapItem, to: destination.mapItem)
                let detour = max(0, (first.expectedTravelTime + second.expectedTravelTime - route.expectedTravelTime) / 60)
                guard detour <= maximumDetour else { continue }
                stops.append(RouteStop(charger: charger, arrivalMinutes: minutes, arrivalMiles: miles, detourMinutes: detour))
            } catch {
                try Task.checkCancellation()
                let ns = error as NSError
                if ns.domain == MKError.errorDomain && ns.code == MKError.Code.loadingThrottled.rawValue { throw MapSearchFailure.throttled }
                failures += 1
            }
        }
        try Task.checkCancellation()
        var notices = ["Driving estimates can change. Detours exclude charging and meal time."]
        if failures > 0 { notices.append("Some areas or driving estimates were unavailable; results may be incomplete.") }
        if unsavedCandidates.count > 12 { notices.append("Driving estimates were checked for 12 nearby chargers plus saved stops. Narrow the window for a more focused search.") }
        notices.append("Charger data: AFDC. U.S. public DC-fast stations; not live availability.")
        if let warning = AFDCChargerProvider.shared.warning { notices.append(warning) }
        let segmentStart = geometry.length * min(1, window.lower / total)
        let segmentEnd = geometry.length * min(1, window.upper / total)
        let segmentCoordinates = (0...100).map { index in
            geometry.coordinate(at: segmentStart + (segmentEnd - segmentStart) * Double(index) / 100)
        }
        return RouteStopResults(route: route,
                                stopSegment: MKPolyline(coordinates: segmentCoordinates, count: segmentCoordinates.count),
                                windowDescription: "\(Int(window.lower))–\(Int(window.upper)) \(window.unit.rawValue.lowercased()) ahead · Max detour \(Int(maximumDetour)) min",
                                stops: stops.sorted { $0.detourMinutes < $1.detourMinutes },
                                destinationName: destination.mapItem.name ?? destinationQuery,
                                startCoordinate: origin.location.coordinate,
                                destinationCoordinate: destination.mapItem.location.coordinate,
                                notice: notices.joined(separator: " "))
    }

    private func drivingRoute(from: MKMapItem, to: MKMapItem) async throws -> MKRoute {
        try Task.checkCancellation()
        let request = MKDirections.Request()
        request.source = from
        request.destination = to
        request.transportType = .automobile
        request.requestsAlternateRoutes = false
        let directions = MKDirections(request: request)
        activeDirections = directions
        defer { if activeDirections === directions { activeDirections = nil } }
        let response = try await directions.calculate()
        try Task.checkCancellation()
        guard let route = response.routes.first else { throw RouteFailure.message("No driving route was found.") }
        return route
    }
}

enum RouteFailure: LocalizedError {
    case message(String)
    var errorDescription: String? { if case .message(let text) = self { return text }; return nil }
}
