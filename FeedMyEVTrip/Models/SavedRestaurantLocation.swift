import CoreLocation
import Foundation
import SwiftData

@Model
final class SavedRestaurantLocation {
    var id: UUID
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var mapItemIdentifier: String?
    var note: String
    var savedAt: Date

    init(
        name: String,
        address: String,
        latitude: Double,
        longitude: Double,
        mapItemIdentifier: String? = nil,
        note: String = ""
    ) {
        id = UUID()
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.mapItemIdentifier = mapItemIdentifier
        self.note = note
        savedAt = Date()
    }

    func matches(placeIdentifier: String?, latitude: Double, longitude: Double) -> Bool {
        if let mapItemIdentifier, let placeIdentifier, mapItemIdentifier == placeIdentifier {
            return true
        }
        let here = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let there = CLLocation(latitude: latitude, longitude: longitude)
        return here.distance(from: there) <= 20
    }
}
