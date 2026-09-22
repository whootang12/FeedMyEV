import MapKit

// MARK: - MapKit adapter

struct ChargerResult: Identifiable {
    let id = UUID()
    let mapItem: MKMapItem

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
