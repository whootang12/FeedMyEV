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
    var savedAt: Date
    var foodNames: String

    init(
        chargerName: String,
        address: String,
        latitude: Double,
        longitude: Double,
        mapItemIdentifier: String? = nil,
        foodNames: [String]
    ) {
        id = UUID()
        self.chargerName = chargerName
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.mapItemIdentifier = mapItemIdentifier
        savedAt = Date()
        self.foodNames = foodNames.joined(separator: "\n")
    }

    var nearbyFoodNames: [String] {
        foodNames.split(separator: "\n").map(String.init)
    }
}
