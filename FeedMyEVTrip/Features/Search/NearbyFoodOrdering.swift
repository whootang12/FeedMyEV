import MapKit

enum NearbyFoodOrdering {
    static func sorted(
        _ places: [MKMapItem],
        from origin: CLLocation,
        savedChains: [SavedRestaurantChain]
    ) -> [MKMapItem] {
        places.sorted { lhs, rhs in
            let lhsMatches = savedChains.contains { $0.matches(placeName: lhs.name) }
            let rhsMatches = savedChains.contains { $0.matches(placeName: rhs.name) }
            if lhsMatches != rhsMatches { return lhsMatches }
            return origin.distance(from: lhs.location) < origin.distance(from: rhs.location)
        }
    }
}
