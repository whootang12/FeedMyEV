import Combine
import MapKit

struct SearchPlace {
    let mapItem: MKMapItem
    let identifier: String?
}

enum MapSearchFailure: Error {
    case throttled
    case networkUnavailable
    case serviceUnavailable
}

@MainActor
final class MapSearchService: ObservableObject {
    private struct CachedPlace: Codable {
        let name: String?
        let address: String?
        let latitude: Double
        let longitude: Double
        let phoneNumber: String?
        let website: String?
        let timeZoneIdentifier: String?
        let category: String?
        let identifier: String?

        init(_ mapItem: MKMapItem) {
            name = mapItem.name
            address = mapItem.addressRepresentations?.fullAddress(
                includingRegion: true,
                singleLine: true
            ) ?? mapItem.address?.fullAddress
            latitude = mapItem.location.coordinate.latitude
            longitude = mapItem.location.coordinate.longitude
            phoneNumber = mapItem.phoneNumber
            website = mapItem.url?.absoluteString
            timeZoneIdentifier = mapItem.timeZone?.identifier
            category = mapItem.pointOfInterestCategory?.rawValue
            identifier = mapItem.identifier?.rawValue
        }

        var searchPlace: SearchPlace {
            let location = CLLocation(latitude: latitude, longitude: longitude)
            let mapItem = MKMapItem(
                location: location,
                address: address.flatMap { MKAddress(fullAddress: $0, shortAddress: nil) }
            )
            mapItem.name = name
            mapItem.phoneNumber = phoneNumber
            mapItem.url = website.flatMap(URL.init(string:))
            mapItem.timeZone = timeZoneIdentifier.flatMap(TimeZone.init(identifier:))
            mapItem.pointOfInterestCategory = category.map(MKPointOfInterestCategory.init(rawValue:))
            return SearchPlace(mapItem: mapItem, identifier: identifier)
        }
    }

    private struct CachedRegion: Codable {
        let centerLatitude: Double
        let centerLongitude: Double
        let latitudeDelta: Double
        let longitudeDelta: Double

        init(_ region: MKCoordinateRegion) {
            centerLatitude = region.center.latitude
            centerLongitude = region.center.longitude
            latitudeDelta = region.span.latitudeDelta
            longitudeDelta = region.span.longitudeDelta
        }

        var region: MKCoordinateRegion {
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: centerLatitude,
                    longitude: centerLongitude
                ),
                span: MKCoordinateSpan(
                    latitudeDelta: latitudeDelta,
                    longitudeDelta: longitudeDelta
                )
            )
        }
    }

    private struct CacheEntry: Codable {
        let key: String
        let kind: String
        let createdAt: Date
        let region: CachedRegion?
        let places: [CachedPlace]
    }

    private struct CacheEnvelope: Codable {
        var entries: [CacheEntry]
    }

    private let cacheLifetime: TimeInterval = 7 * 24 * 60 * 60
    private let cacheDefaultsKey = "MapSearchService.cache.v1"
    private let maximumCacheEntries = 100
    private var cacheEntries: [CacheEntry]
    private var activeSearch: MKLocalSearch?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        cacheEntries = []
        if let data = defaults.data(forKey: cacheDefaultsKey),
           let envelope = try? JSONDecoder().decode(CacheEnvelope.self, from: data) {
            cacheEntries = envelope.entries.filter {
                $0.kind != "chargers" && Date().timeIntervalSince($0.createdAt) < cacheLifetime
            }
        }
    }

    private let defaults: UserDefaults

    func cancelActiveSearch() {
        activeSearch?.cancel()
        activeSearch = nil
    }

    func resolveDestination(_ query: String) async throws -> SearchPlace? {
        let key = "destination:\(query.lowercased())"
        if let cached = cachedPlaces(for: key)?.first {
            return cached
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let response = try await execute(request: request)
        let places = response.mapItems.map(CachedPlace.init)
        if !places.isEmpty {
            store(key: key, kind: "destination", region: nil, places: places)
        }
        return places.first?.searchPlace
    }

    func searchFood(
        around coordinate: CLLocationCoordinate2D,
        radius: CLLocationDistance,
        categories: [MKPointOfInterestCategory]
    ) async throws -> [SearchPlace] {
        let categoryKey = categories.map(\.rawValue).sorted().joined(separator: ",")
        let key = String(
            format: "food:%.4f:%.4f:%.0f:%@",
            coordinate.latitude,
            coordinate.longitude,
            radius,
            categoryKey
        )
        if let cached = cachedPlaces(for: key), !cached.isEmpty {
            return cached
        }

        let request = MKLocalPointsOfInterestRequest(center: coordinate, radius: radius)
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: categories)
        let response = try await execute(pointsOfInterestRequest: request)
        let places = response.mapItems.map(CachedPlace.init)
        if !places.isEmpty {
            store(key: key, kind: "food", region: nil, places: places)
        }
        return places.map(\.searchPlace)
    }

    private func execute(request: MKLocalSearch.Request) async throws -> MKLocalSearch.Response {
        try await executeSearch { MKLocalSearch(request: request) }
    }

    private func execute(
        pointsOfInterestRequest request: MKLocalPointsOfInterestRequest
    ) async throws -> MKLocalSearch.Response {
        try await executeSearch { MKLocalSearch(request: request) }
    }

    private func executeSearch(
        makeSearch: () -> MKLocalSearch
    ) async throws -> MKLocalSearch.Response {
        for attempt in 0...2 {
            try Task.checkCancellation()
            activeSearch?.cancel()
            let search = makeSearch()
            activeSearch = search

            do {
                let response = try await search.start()
                if activeSearch === search { activeSearch = nil }
                return response
            } catch {
                if activeSearch === search { activeSearch = nil }
                if error is CancellationError { throw error }

                let mappedError = mapError(error)
                guard mappedError == .throttled, attempt < 2 else {
                    throw mappedError
                }

                let baseDelay = 0.75 * pow(2, Double(attempt))
                let delay = baseDelay + Double.random(in: 0.1...0.35)
                try await Task.sleep(for: .seconds(delay))
            }
        }

        throw MapSearchFailure.serviceUnavailable
    }

    private func mapError(_ error: Error) -> MapSearchFailure {
        let nsError = error as NSError
        if nsError.domain == MKError.errorDomain,
           nsError.code == Int(MKError.Code.loadingThrottled.rawValue) {
            return .throttled
        }
        if nsError.domain == NSURLErrorDomain {
            return .networkUnavailable
        }
        return .serviceUnavailable
    }

    private func cachedPlaces(for key: String) -> [SearchPlace]? {
        cacheEntries.first(where: { $0.key == key })?.places.map(\.searchPlace)
    }

    private func cachedChargerPlaces(overlapping region: MKCoordinateRegion) -> [CachedPlace] {
        cacheEntries
            .filter {
                $0.kind == "chargers"
                    && $0.region.map { regionsOverlap($0.region, region) } == true
            }
            .flatMap(\.places)
    }

    private func store(
        key: String,
        kind: String,
        region: MKCoordinateRegion?,
        places: [CachedPlace]
    ) {
        cacheEntries.removeAll { $0.key == key }
        cacheEntries.append(
            CacheEntry(
                key: key,
                kind: kind,
                createdAt: Date(),
                region: region.map(CachedRegion.init),
                places: places
            )
        )
        cacheEntries = cacheEntries
            .filter { Date().timeIntervalSince($0.createdAt) < cacheLifetime }
            .sorted { $0.createdAt > $1.createdAt }
        if cacheEntries.count > maximumCacheEntries {
            cacheEntries.removeLast(cacheEntries.count - maximumCacheEntries)
        }
        persistCache()
    }

    private func persistCache() {
        guard let data = try? JSONEncoder().encode(CacheEnvelope(entries: cacheEntries)) else {
            return
        }
        defaults.set(data, forKey: cacheDefaultsKey)
    }

    private func merge(_ places: [CachedPlace]) -> [CachedPlace] {
        var keys = Set<String>()
        return places.filter { place in
            let key = "\(Int((place.latitude * 100_000).rounded())):"
                + "\(Int((place.longitude * 100_000).rounded()))"
            return keys.insert(key).inserted
        }
    }

    private func regionCacheKey(prefix: String, region: MKCoordinateRegion) -> String {
        String(
            format: "%@:%.2f:%.2f:%.2f:%.2f",
            prefix,
            region.center.latitude,
            region.center.longitude,
            region.span.latitudeDelta,
            region.span.longitudeDelta
        )
    }

    private func regionsOverlap(_ lhs: MKCoordinateRegion, _ rhs: MKCoordinateRegion) -> Bool {
        let latitudeDistance = abs(lhs.center.latitude - rhs.center.latitude)
        let longitudeDistance = abs(lhs.center.longitude - rhs.center.longitude)
        return latitudeDistance <= (lhs.span.latitudeDelta + rhs.span.latitudeDelta) / 2
            && longitudeDistance <= (lhs.span.longitudeDelta + rhs.span.longitudeDelta) / 2
    }
}
