import SwiftUI

struct ChargingResultCard: View {
    let name: String
    let address: String
    let arrival: String
    let detour: String
    let foodSummary: String
    let connectorSummary: String
    let isSaved: Bool

    init(
        name: String,
        address: String,
        arrival: String,
        detour: String,
        foodSummary: String,
        connectorSummary: String,
        isSaved: Bool
    ) {
        self.name = name
        self.address = address
        self.arrival = arrival
        self.detour = detour
        self.foodSummary = foodSummary
        self.connectorSummary = connectorSummary
        self.isSaved = isSaved
    }

    init(result: SearchExperiencePreviewState.Result) {
        self.init(
            name: result.name,
            address: result.address,
            arrival: result.arrival,
            detour: result.detour,
            foodSummary: result.foodSummary,
            connectorSummary: result.connectorSummary,
            isSaved: result.isSaved
        )
    }

    var body: some View {
        Button {} label: {
            VStack(alignment: .leading, spacing: 11) {
                HStack(alignment: .top) {
                    Image(systemName: isSaved ? "bookmark.fill" : "bolt.fill")
                        .foregroundStyle(isSaved ? .purple : .green)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(name)
                            .font(.headline)
                        Text(address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                }

                ViewThatFits {
                    HStack(spacing: 8) {
                        ChargingResultMetric(systemImage: "clock", text: arrival)
                        ChargingResultMetric(systemImage: "arrow.triangle.branch", text: detour)
                    }
                    VStack(alignment: .leading, spacing: 7) {
                        ChargingResultMetric(systemImage: "clock", text: arrival)
                        ChargingResultMetric(systemImage: "arrow.triangle.branch", text: detour)
                    }
                }

                Label(foodSummary, systemImage: "fork.knife")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(connectorSummary)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(.background.opacity(0.86), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

private struct ChargingResultMetric: View {
    let systemImage: String
    let text: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(.blue.opacity(0.1), in: Capsule())
    }
}

#Preview("Charging result card") {
    ChargingResultCard(
        name: "White Marsh Mall Charging",
        address: "8200 Perry Hall Boulevard, Baltimore, MD",
        arrival: "1 hr 24 min ahead",
        detour: "+6 min detour",
        foodSummary: "Chipotle, Panera Bread, and 2 more within a 10 minute walk",
        connectorSummary: "CCS · NACS · 12 DC-fast ports",
        isSaved: true
    )
    .padding()
    .background(Color(uiColor: .systemGroupedBackground))
}
