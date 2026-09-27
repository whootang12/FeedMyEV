import Foundation
import SwiftData

@Model
final class SavedRestaurantChain {
    var id: UUID
    var name: String
    var savedAt: Date

    init(name: String) {
        id = UUID()
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        savedAt = Date()
    }

    static func normalizedName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    func matches(placeName: String?) -> Bool {
        guard let placeName else { return false }
        let place = Self.normalizedName(placeName)
        let chain = Self.normalizedName(name)
        return !place.isEmpty && place == chain
    }
}
