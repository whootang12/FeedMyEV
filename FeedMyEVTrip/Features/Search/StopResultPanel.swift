import SwiftUI

// MARK: - Display models

struct StopSummary {
    let chargerName: String
    let address: String
    let foodOptions: [FoodSummary]
    var metadata: String? = nil
}

struct FoodSummary: Identifiable {
    let id: String
    let name: String
    let distanceAndWalk: String
}

enum StopPanelState {
    case welcome
    case message(String)
    case selected(
        stop: StopSummary,
        isLoadingFood: Bool,
        isSaved: Bool,
        isShowingStopArea: Bool
    )
}

struct StopResultPanel: View {
    let state: StopPanelState
    @Binding var note: String
    var onSave: () -> Void = {}
    var onDirections: () -> Void = {}
    var onViewDetails: () -> Void = {}
    var onSelectFood: (FoodSummary) -> Void = { _ in }

    init(
        state: StopPanelState,
        note: Binding<String> = .constant(""),
        onSave: @escaping () -> Void = {},
        onDirections: @escaping () -> Void = {},
        onViewDetails: @escaping () -> Void = {},
        onSelectFood: @escaping (FoodSummary) -> Void = { _ in }
    ) {
        self.state = state
        _note = note
        self.onSave = onSave
        self.onDirections = onDirections
        self.onViewDetails = onViewDetails
        self.onSelectFood = onSelectFood
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch state {
            case .welcome:
                welcomeContent
            case .message(let message):
                Label(message, systemImage: "magnifyingglass")
                    .font(.subheadline)
            case .selected(let stop, let isLoadingFood, let isSaved, let isShowingStopArea):
                selectedContent(
                    stop,
                    isLoadingFood: isLoadingFood,
                    isSaved: isSaved,
                    isShowingStopArea: isShowingStopArea
                )
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
        isSaved: Bool,
        isShowingStopArea: Bool
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

        if let metadata = stop.metadata {
            Text(metadata).font(.caption).foregroundStyle(.secondary)
        }

        if isLoadingFood {
            ProgressView("Checking nearby food…")
                .font(.subheadline)
        } else if stop.foodOptions.isEmpty {
            Text("No nearby food found within your walking range.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            Text("\(stop.foodOptions.count) food options found within your walking range")
                .font(.subheadline)

            ForEach(stop.foodOptions.prefix(isShowingStopArea ? stop.foodOptions.count : 3)) { food in
                Button {
                    onSelectFood(food)
                } label: {
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

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }

        if !isShowingStopArea {
            Button(action: onViewDetails) {
                VStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.title2)
                    Text("View details")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle(radius: 16))
            .controlSize(.large)
            .tint(.blue)
        }

        TextField("Notes", text: $note, axis: .vertical)
            .textFieldStyle(.roundedBorder)
            .lineLimit(2...6)

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
