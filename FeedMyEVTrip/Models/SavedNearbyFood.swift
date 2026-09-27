import Foundation
import MapKit

struct SavedNearbyFood: Codable, Equatable, Identifiable {
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var phoneNumber: String?
    var website: String?
    var mapItemIdentifier: String?

    var id: String {
        "\(name)|\(latitude)|\(longitude)"
    }

    init(
        name: String,
        address: String,
        latitude: Double,
        longitude: Double,
        phoneNumber: String? = nil,
        website: String? = nil,
        mapItemIdentifier: String? = nil
    ) {
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.phoneNumber = phoneNumber
        self.website = website
        self.mapItemIdentifier = mapItemIdentifier
    }

    init?(mapItem: MKMapItem) {
        let trimmed = mapItem.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return nil }
        name = trimmed
        address = mapItem.addressRepresentations?.fullAddress(
            includingRegion: true,
            singleLine: true
        ) ?? mapItem.address?.fullAddress ?? ""
        latitude = mapItem.location.coordinate.latitude
        longitude = mapItem.location.coordinate.longitude
        phoneNumber = mapItem.phoneNumber
        website = mapItem.url?.absoluteString
        mapItemIdentifier = mapItem.identifier?.rawValue
    }

    var mapItem: MKMapItem {
        let item = MKMapItem(
            location: CLLocation(latitude: latitude, longitude: longitude),
            address: address.isEmpty ? nil : MKAddress(fullAddress: address, shortAddress: nil)
        )
        item.name = name
        item.phoneNumber = phoneNumber
        item.url = website.flatMap(URL.init(string:))
        return item
    }

    static func encode(_ places: [SavedNearbyFood]) -> String {
        guard let data = try? JSONEncoder().encode(places),
              let text = String(data: data, encoding: .utf8) else {
            return ""
        }
        return text
    }

    static func decode(_ text: String) -> [SavedNearbyFood] {
        guard let data = text.data(using: .utf8),
              let places = try? JSONDecoder().decode([SavedNearbyFood].self, from: data) else {
            return []
        }
        return places
    }
}
