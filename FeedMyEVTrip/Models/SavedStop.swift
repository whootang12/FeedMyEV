import Foundation
import SwiftData

// MARK: - Persistence model

@Model
final class SavedStop {
    var id: UUID
    var chargerName: String
    var address: String
    var latitude: Double
    var longitude: Double
    var mapItemIdentifier: String?
    var afdcStationID: Int?
    var savedAt: Date
    var foodNames: String
    var nearbyFoodData: String = ""
    var note: String = ""

    init(
        chargerName: String,
        address: String,
        latitude: Double,
        longitude: Double,
        mapItemIdentifier: String? = nil,
        afdcStationID: Int? = nil,
        foodNames: [String],
        nearbyFood: [SavedNearbyFood] = [],
        note: String = ""
    ) {
        id = UUID()
        self.chargerName = chargerName
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.mapItemIdentifier = mapItemIdentifier
        self.afdcStationID = afdcStationID
        savedAt = Date()
        if nearbyFood.isEmpty {
            self.foodNames = foodNames.joined(separator: "\n")
            self.nearbyFoodData = ""
        } else {
            self.foodNames = nearbyFood.map(\.name).joined(separator: "\n")
            self.nearbyFoodData = SavedNearbyFood.encode(nearbyFood)
        }
        self.note = note
    }

    var nearbyFoodNames: [String] {
        foodNames.split(separator: "\n").map(String.init)
    }

    var nearbyFoodPlaces: [SavedNearbyFood] {
        SavedNearbyFood.decode(nearbyFoodData)
    }
}
