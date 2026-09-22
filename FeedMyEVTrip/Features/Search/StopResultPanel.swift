import SwiftUI

// MARK: - Display models

struct StopSummary {
    let chargerName: String
    let address: String
    let foodOptions: [FoodSummary]
}

struct FoodSummary {
    let name: String
    let distanceAndWalk: String
}

enum StopPanelState {
    case welcome
    case message(String)
    case selected(stop: StopSummary, isLoadingFood: Bool, isSaved: Bool)
}

struct StopResultPanel: View {
    let state: StopPanelState
    var onSave: () -> Void = {}
    var onDirections: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch state {
            case .welcome:
                welcomeContent
            case .message(let message):
                Label(message, systemImage: "magnifyingglass")
                    .font(.subheadline)
            case .selected(let stop, let isLoadingFood, let isSaved):
                selectedContent(stop, isLoadingFood: isLoadingFood, isSaved: isSaved)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial)
    }

    private var welcomeContent: some View {
        Group {
            Text("Find a better charging stop")
                .font(.headline)
            Text("Search for where you’re headed, then choose a charger to see food within walking distance.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func selectedContent(
        _ stop: StopSummary,
        isLoadingFood: Bool,
        isSaved: Bool
    ) -> some View {
        Label("Charging stop", systemImage: "bolt.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.green)

        Text(stop.chargerName)
            .font(.headline)

        Text(stop.address)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)

        if isLoadingFood {
            ProgressView("Checking nearby food…")
                .font(.subheadline)
        } else if stop.foodOptions.isEmpty {
            Text("No nearby food found within about a mile.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            Text("\(stop.foodOptions.count) food options found within about a mile")
                .font(.subheadline)

            ForEach(Array(stop.foodOptions.prefix(3).enumerated()), id: \.offset) { _, food in
                HStack(spacing: 8) {
                    Image(systemName: "fork.knife")
                        .foregroundStyle(.orange)

                    Text(food.name)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)

                    Spacer()

                    Text(food.distanceAndWalk)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }

        HStack {
            Button(action: onSave) {
                Label(
                    isSaved ? "Saved" : "Save",
                    systemImage: isSaved ? "bookmark.fill" : "bookmark"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(isSaved || isLoadingFood)

            Button(action: onDirections) {
                Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
    }
}
