import MapKit
import SwiftData
import SwiftUI

struct SelectedFood: Identifiable {
    let id = UUID()
    let mapItem: MKMapItem
    let charger: MKMapItem
    let distanceAndWalk: String
}

struct FoodDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var modelContext
    @Query private var savedChains: [SavedRestaurantChain]
    @Query private var savedLocations: [SavedRestaurantLocation]

    let food: MKMapItem
    let charger: MKMapItem
    let distanceAndWalk: String

    @State private var noteDraft = ""
    @State private var isSyncingNote = false

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

                Section {
                    Button(action: toggleChain) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isChainSaved ? "Saved chain" : "Save chain")
                                if let chainName {
                                    Text(chainName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } icon: {
                            Image(systemName: isChainSaved ? "bookmark.fill" : "bookmark")
                        }
                    }
                    .disabled(chainName == nil)

                    Button(action: toggleLocation) {
                        Label(
                            isLocationSaved ? "Saved location" : "Save this location",
                            systemImage: isLocationSaved ? "mappin.circle.fill" : "mappin.circle"
                        )
                    }

                    TextField("Notes", text: $noteDraft, axis: .vertical)
                        .lineLimit(3...8)
                } header: {
                    Text("Save")
                } footer: {
                    Text("A saved chain matches this restaurant’s name wherever it appears. Notes belong to this location.")
                }

                Section("More details") {
                    Button {
                        MKMapItem.openMaps(with: [charger, food], launchOptions: [
                            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
                        ])
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
            .onAppear {
                replaceNoteDraft(matchingLocation()?.note ?? "")
            }
            .onChange(of: noteDraft) { _, newValue in
                if isSyncingNote {
                    isSyncingNote = false
                    return
                }
                persistLocationNote(newValue)
            }
        }
    }

    private var chainName: String? {
        let trimmed = food.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private var isChainSaved: Bool {
        savedChains.contains { $0.matches(placeName: food.name) }
    }

    private var isLocationSaved: Bool {
        savedLocations.contains { matchesCurrentPlace($0) }
    }

    private var address: String {
        food.addressRepresentations?.fullAddress(
            includingRegion: true,
            singleLine: true
        ) ?? food.address?.fullAddress ?? "Address unavailable"
    }

    private func toggleChain() {
        guard let chainName else { return }
        let matches = fetchedChains().filter { $0.matches(placeName: chainName) }
        if matches.isEmpty {
            modelContext.insert(SavedRestaurantChain(name: chainName))
        } else {
            matches.forEach(modelContext.delete)
        }
    }

    private func toggleLocation() {
        let matches = fetchedLocations().filter(matchesCurrentPlace)
        if matches.isEmpty {
            modelContext.insert(makeLocation(note: noteDraft))
        } else {
            matches.forEach(modelContext.delete)
            replaceNoteDraft("")
        }
    }

    private func persistLocationNote(_ text: String) {
        if let location = fetchedLocations().first(where: matchesCurrentPlace) {
            if location.note != text { location.note = text }
            return
        }
        guard !text.isEmpty else { return }
        modelContext.insert(makeLocation(note: text))
    }

    private func replaceNoteDraft(_ text: String) {
        guard noteDraft != text else { return }
        isSyncingNote = true
        noteDraft = text
    }

    private func matchesCurrentPlace(_ location: SavedRestaurantLocation) -> Bool {
        location.matches(
            placeIdentifier: food.identifier?.rawValue,
            latitude: food.location.coordinate.latitude,
            longitude: food.location.coordinate.longitude
        )
    }

    private func makeLocation(note: String) -> SavedRestaurantLocation {
        let trimmedName = food.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return SavedRestaurantLocation(
            name: trimmedName.isEmpty ? "Restaurant" : trimmedName,
            address: storedAddress,
            latitude: food.location.coordinate.latitude,
            longitude: food.location.coordinate.longitude,
            mapItemIdentifier: food.identifier?.rawValue,
            note: note
        )
    }

    private var storedAddress: String {
        let formatted = food.addressRepresentations?.fullAddress(
            includingRegion: true,
            singleLine: true
        ) ?? food.address?.fullAddress ?? ""
        return formatted == "Address unavailable" ? "" : formatted
    }

    private func fetchedChains() -> [SavedRestaurantChain] {
        (try? modelContext.fetch(FetchDescriptor<SavedRestaurantChain>())) ?? []
    }

    private func fetchedLocations() -> [SavedRestaurantLocation] {
        (try? modelContext.fetch(FetchDescriptor<SavedRestaurantLocation>())) ?? []
    }

    private func matchingLocation() -> SavedRestaurantLocation? {
        fetchedLocations().first(where: matchesCurrentPlace)
    }

    private func phoneURL(_ phoneNumber: String) -> URL {
        let allowed = phoneNumber.filter { $0.isNumber || $0 == "+" }
        return URL(string: "tel:\(allowed)")!
    }

    private var googleMapsURL: URL? {
        let origin = charger.location.coordinate
        let destination = food.location.coordinate
        var components = URLComponents(string: "https://www.google.com/maps/dir/")
        components?.queryItems = [
            URLQueryItem(name: "api", value: "1"),
            URLQueryItem(name: "origin", value: "\(origin.latitude),\(origin.longitude)"),
            URLQueryItem(name: "destination", value: "\(destination.latitude),\(destination.longitude)"),
            URLQueryItem(name: "travelmode", value: "walking")
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
