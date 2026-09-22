import SwiftUI

private let previewStop = StopSummary(
    chargerName: "ChargePoint Charging Station",
    address: "15 N Main Street, Pennington, NJ 08534",
    foodOptions: [
        FoodSummary(id: "front-porch", name: "The Front Porch", distanceAndWalk: "420 ft · ~2 min walk"),
        FoodSummary(id: "vitos", name: "Vito's Pizza", distanceAndWalk: "760 ft · ~4 min walk"),
        FoodSummary(id: "coffee", name: "Pennington Coffee House", distanceAndWalk: "1,120 ft · ~5 min walk")
    ]
)

#Preview("Welcome") {
    StopResultPanel(state: .welcome)
}

#Preview("Food results") {
    StopResultPanel(
        state: .selected(
            stop: previewStop,
            isLoadingFood: false,
            isSaved: false,
            isShowingStopArea: false
        )
    )
}

#Preview("Loading food") {
    StopResultPanel(
        state: .selected(
            stop: previewStop,
            isLoadingFood: true,
            isSaved: false,
            isShowingStopArea: false
        )
    )
}

#Preview("No food nearby") {
    StopResultPanel(
        state: .selected(
            stop: StopSummary(
                chargerName: "Rural EV Charging Station",
                address: "42 Country Road, Hopewell, NJ 08525",
                foodOptions: []
            ),
            isLoadingFood: false,
            isSaved: true,
            isShowingStopArea: false
        )
    )
}

#Preview("Map detail active") {
    StopResultPanel(
        state: .selected(
            stop: previewStop,
            isLoadingFood: false,
            isSaved: false,
            isShowingStopArea: true
        )
    )
}
