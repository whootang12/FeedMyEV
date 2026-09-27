import MapKit

// MARK: - MapKit adapter

struct ChargerResult: Identifiable {
    let id = UUID()
    let mapItem: MKMapItem
    let placeIdentifier: String?
    let afdcStationID: Int?
    let metadataSummary: String?

    init(mapItem: MKMapItem, placeIdentifier: String? = nil, afdcStationID: Int? = nil, metadataSummary: String? = nil) {
        self.afdcStationID = afdcStationID
        self.metadataSummary = metadataSummary
        self.mapItem = mapItem
        self.placeIdentifier = placeIdentifier ?? mapItem.identifier?.rawValue
    }

    init(station: AFDCStation) {
        let item = MKMapItem(
            location: CLLocation(latitude: station.latitude!, longitude: station.longitude!),
            address: MKAddress(fullAddress: station.address, shortAddress: nil)
        )
        item.name = station.stationName
        item.pointOfInterestCategory = .evCharger
        self.init(mapItem: item, afdcStationID: station.id, metadataSummary: station.summary)
    }

    init(savedStop: SavedStop) {
        let item = MKMapItem(
            location: CLLocation(latitude: savedStop.latitude, longitude: savedStop.longitude),
            address: MKAddress(fullAddress: savedStop.address, shortAddress: nil)
        )
        item.name = savedStop.chargerName
        self.init(mapItem: item, placeIdentifier: savedStop.mapItemIdentifier, afdcStationID: savedStop.afdcStationID)
    }

    func matches(_ other: ChargerResult) -> Bool {
        if let afdcStationID, let otherID = other.afdcStationID { return afdcStationID == otherID }
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
        ) ?? mapItem.address?.fullAddress ?? "Address unavailable"
    }
}
