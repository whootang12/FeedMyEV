import MapKit
import SwiftUI

struct SavedStopDetailsView: View {
    let stop: SavedStop

    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude)
    }

    private var mapItem: MKMapItem {
        let item = MKMapItem(
            location: CLLocation(latitude: stop.latitude, longitude: stop.longitude),
            address: nil
        )
        item.name = stop.chargerName
        return item
    }

    var body: some View {
        List {
            Section {
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: coordinate,
                    latitudinalMeters: 1_500,
                    longitudinalMeters: 1_500
                )), interactionModes: []) {
                    Marker(stop.chargerName, systemImage: "bolt.fill", coordinate: coordinate)
                        .tint(.green)
                }
                .frame(height: 220)
                .listRowInsets(EdgeInsets())
                .accessibilityLabel("Map showing \(stop.chargerName)")

                Label(stop.chargerName, systemImage: "bolt.fill")
                    .font(.title2.weight(.semibold))

                if !stop.address.isEmpty {
                    Label(stop.address, systemImage: "mappin.and.ellipse")
                        .textSelection(.enabled)
                }

                LabeledContent("Saved", value: stop.savedAt.formatted(date: .abbreviated, time: .omitted))
            }

            Section {
                Button {
                    mapItem.openInMaps(launchOptions: [
                        MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
                    ])
                } label: {
                    Label("Driving directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                }

                Button {
                    mapItem.openInMaps()
                } label: {
                    Label("Open in Apple Maps", systemImage: "map")
                }
            }
            .tint(.green)

            Section {
                if stop.nearbyFoodNames.isEmpty {
                    Text("No nearby food was saved with this stop.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(stop.nearbyFoodNames.enumerated()), id: \.offset) { _, name in
                        Label(name, systemImage: "fork.knife")
                    }
                }
            } header: {
                Text("Nearby food")
            } footer: {
                Text("Food options recorded when you saved this stop.")
            }
        }
        .navigationTitle("Saved Stop")
        .navigationBarTitleDisplayMode(.inline)
    }
}
