import MapKit

// MARK: - MapKit adapter

struct ChargerResult: Identifiable {
    let id = UUID()
    let mapItem: MKMapItem
    let placeIdentifier: String?

    init(mapItem: MKMapItem, placeIdentifier: String? = nil) {
        self.mapItem = mapItem
        self.placeIdentifier = placeIdentifier ?? mapItem.identifier?.rawValue
    }

    init(savedStop: SavedStop) {
        let item = MKMapItem(
            location: CLLocation(latitude: savedStop.latitude, longitude: savedStop.longitude),
            address: MKAddress(fullAddress: savedStop.address, shortAddress: nil)
        )
        item.name = savedStop.chargerName
        self.init(mapItem: item, placeIdentifier: savedStop.mapItemIdentifier)
    }

    func matches(_ other: ChargerResult) -> Bool {
        if let placeIdentifier, let otherIdentifier = other.placeIdentifier,
           placeIdentifier == otherIdentifier { return true }
        return mapItem.location.distance(from: other.mapItem.location) <= 20
    }

    var name: String {
        mapItem.name ?? "EV Charger"
    }

    var coordinate: CLLocationCoordinate2D {
        mapItem.location.coordinate
    }

    var address: String {
        mapItem.addressRepresentations?.fullAddress(
            includingRegion: false,
            singleLine: true
        ) ?? "Address unavailable"
    }
}
