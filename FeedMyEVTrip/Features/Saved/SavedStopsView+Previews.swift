import SwiftData
import SwiftUI

#Preview("Empty") {
    SavedStopsView()
        .modelContainer(for: SavedStop.self, inMemory: true)
}

#Preview("Saved stops") {
    SavedStopsView()
        .modelContainer(savedStopsPreviewContainer())
}

#Preview("Saved map") {
    SavedStopsView(showMap: true)
        .modelContainer(savedStopsPreviewContainer())
}

@MainActor
private func savedStopsPreviewContainer() -> ModelContainer {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: SavedStop.self,
        configurations: configuration
    )

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

    return container
}
