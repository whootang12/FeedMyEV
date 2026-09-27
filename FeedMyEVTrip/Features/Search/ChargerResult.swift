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
