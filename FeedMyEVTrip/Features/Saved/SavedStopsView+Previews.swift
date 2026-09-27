import SwiftData
import SwiftUI

#Preview("Empty") {
    SavedStopsView()
        .modelContainer(for: SavedStore.modelTypes, inMemory: true)
}

#Preview("Saved stops") {
    SavedStopsView()
        .modelContainer(savedStopsPreviewContainer())
}

#Preview("Saved map") {
    SavedStopsView(showMap: true)
        .modelContainer(savedStopsPreviewContainer())
}

#Preview("Saved food") {
    SavedStopsView(section: .food)
        .modelContainer(savedStopsPreviewContainer())
}

#Preview("Saved stop details") {
    savedStopDetailsPreview()
}

#Preview("Saved location details") {
    savedLocationDetailsPreview()
}

@MainActor
private func savedStopDetailsPreview() -> some View {
    let container = previewModelContainer()
    let stop = SavedStop(
        chargerName: "Tesla Supercharger",
        address: "3371 Brunswick Pike, Lawrenceville, NJ 08648",
        latitude: 40.2937,
        longitude: -74.6818,
        foodNames: [],
        nearbyFood: [
            SavedNearbyFood(
                name: "Turning Point",
                address: "3371 Brunswick Pike, Lawrenceville, NJ 08648",
                latitude: 40.2942,
                longitude: -74.6821
            ),
            SavedNearbyFood(
                name: "Shake Shack",
                address: "3371 Brunswick Pike, Lawrenceville, NJ 08648",
                latitude: 40.2931,
                longitude: -74.6812
            )
        ],
        note: "Pull-through stalls"
    )
    container.mainContext.insert(stop)
    return NavigationStack {
        SavedStopDetailsView(stop: stop)
    }
    .modelContainer(container)
}

@MainActor
private func savedLocationDetailsPreview() -> some View {
    let container = previewModelContainer()
    let location = SavedRestaurantLocation(
        name: "The Front Porch",
        address: "20 N Main Street, Pennington, NJ 08534",
        latitude: 40.3287,
        longitude: -74.7902,
        note: "Sit outside if the weather is good."
    )
    container.mainContext.insert(location)
    return NavigationStack {
        SavedRestaurantLocationDetailsView(location: location)
    }
    .modelContainer(container)
}

@MainActor
private func previewModelContainer() -> ModelContainer {
    try! SavedStore.makeContainer(inMemory: true)
}

@MainActor
private func savedStopsPreviewContainer() -> ModelContainer {
    let container = try! SavedStore.makeContainer(inMemory: true)

    let samples = [
        SavedStop(
            chargerName: "ChargePoint Charging Station",
            address: "15 N Main Street, Pennington, NJ 08534",
            latitude: 40.3284,
            longitude: -74.7907,
            foodNames: ["The Front Porch", "Vito's Pizza", "Pennington Coffee House"]
        ),
        SavedStop(
            chargerName: "Tesla Supercharger",
            address: "3371 Brunswick Pike, Lawrenceville, NJ 08648",
            latitude: 40.2937,
            longitude: -74.6818,
            foodNames: ["Turning Point", "Shake Shack", "Sweetgreen"]
        ),
        SavedStop(
            chargerName: "EVgo Fast Charging",
            address: "500 Marketplace Boulevard, Hamilton, NJ 08691",
            latitude: 40.1957,
            longitude: -74.6412,
            foodNames: []
        )
    ]

    for (daysAgo, stop) in samples.enumerated() {
        stop.savedAt = Calendar.current.date(
            byAdding: .day,
            value: -daysAgo,
            to: Date()
        ) ?? Date()
        container.mainContext.insert(stop)
    }

    let chain = SavedRestaurantChain(name: "Wawa")
    chain.savedAt = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    container.mainContext.insert(chain)

    let location = SavedRestaurantLocation(
        name: "The Front Porch",
        address: "20 N Main Street, Pennington, NJ 08534",
        latitude: 40.3287,
        longitude: -74.7902,
        note: "Sit outside if the weather is good."
    )
    container.mainContext.insert(location)

    return container
}
