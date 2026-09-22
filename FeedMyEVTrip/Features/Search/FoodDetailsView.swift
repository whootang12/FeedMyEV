import MapKit
import SwiftUI

struct SelectedFood: Identifiable {
    let id = UUID()
    let mapItem: MKMapItem
    let distanceAndWalk: String
}

struct FoodDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let food: MKMapItem
    let distanceAndWalk: String

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label(distanceAndWalk, systemImage: "figure.walk")

                    Label(address, systemImage: "mappin.and.ellipse")

                    if let phoneNumber = food.phoneNumber {
                        Link(destination: phoneURL(phoneNumber)) {
                            Label(phoneNumber, systemImage: "phone")
                        }
                    }

                    if let website = food.url {
                        Link(destination: website) {
                            Label("Website", systemImage: "safari")
                        }
                    }
                }

                Section("More details") {
                    Button {
                        food.openInMaps()
                    } label: {
                        Label("Open in Apple Maps", systemImage: "map.fill")
                    }

                    Button {
                        if let googleMapsURL { openURL(googleMapsURL) }
                    } label: {
                        Label("Open in Google Maps", systemImage: "globe")
                    }

                    Button {
                        if let yelpURL { openURL(yelpURL) }
                    } label: {
                        Label("Search on Yelp", systemImage: "star.bubble")
                    }
                }
            }
            .navigationTitle(food.name ?? "Food details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var address: String {
        food.addressRepresentations?.fullAddress(
            includingRegion: true,
            singleLine: true
        ) ?? food.address?.fullAddress ?? "Address unavailable"
    }

    private func phoneURL(_ phoneNumber: String) -> URL {
        let allowed = phoneNumber.filter { $0.isNumber || $0 == "+" }
        return URL(string: "tel:\(allowed)")!
    }

    private var googleMapsURL: URL? {
        var components = URLComponents(string: "https://www.google.com/maps/search/")
        components?.queryItems = [
            URLQueryItem(name: "api", value: "1"),
            URLQueryItem(name: "query", value: "\(food.name ?? "Food"), \(address)")
        ]
        return components?.url
    }

    private var yelpURL: URL? {
        let coordinate = food.location.coordinate
        var components = URLComponents(string: "https://www.yelp.com/search")
        components?.queryItems = [
            URLQueryItem(name: "find_desc", value: food.name ?? "Food"),
            URLQueryItem(
                name: "find_loc",
                value: "\(coordinate.latitude),\(coordinate.longitude)"
            )
        ]
        return components?.url
    }
}
