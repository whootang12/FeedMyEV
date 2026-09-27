import MapKit
import SwiftUI

#Preview("Food details") {
    FoodDetailsView(
        food: previewFoodItem(),
        charger: previewChargerItem(),
        distanceAndWalk: "760 ft · ~4 min walk"
    )
}

private func previewChargerItem() -> MKMapItem {
    let location = CLLocation(latitude: 40.3294, longitude: -74.7910)
    let item = MKMapItem(location: location, address: nil)
    item.name = "Pennington Supercharger"
    return item
}

private func previewFoodItem() -> MKMapItem {
    let location = CLLocation(latitude: 40.3287, longitude: -74.7902)
    let address = MKAddress(
        fullAddress: "20 N Main Street, Pennington, NJ 08534",
        shortAddress: "20 N Main Street"
    )
    let item = MKMapItem(location: location, address: address)
    item.name = "The Front Porch"
    item.phoneNumber = "(609) 555-0142"
    item.url = URL(string: "https://example.com")
    return item
}
