import SwiftUI

enum SearchDrawerSize {
    case compact
    case medium
    case expanded

    func height(availableHeight: CGFloat) -> CGFloat {
        switch self {
        case .compact:
            min(150, availableHeight * 0.25)
        case .medium:
            availableHeight * 0.5
        case .expanded:
            availableHeight * 0.88
        }
    }
}

struct SearchDrawerSurface<Content: View>: View {
    @Binding var size: SearchDrawerSize
    let availableHeight: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(height: size.height(availableHeight: availableHeight))
            .frame(maxWidth: .infinity)
            .background(.regularMaterial)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 26, topTrailingRadius: 26))
            .shadow(color: .black.opacity(0.16), radius: 18, y: -4)
            .background(alignment: .bottom) {
                Rectangle()
                    .fill(.regularMaterial)
                    .frame(height: 110)
                    .offset(y: 100)
                    .allowsHitTesting(false)
            }
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        withAnimation(.snappy) {
                            if value.translation.height < -25 {
                                size = size == .compact ? .medium : .expanded
                            } else if value.translation.height > 25 {
                                size = size == .expanded ? .medium : .compact
                            }
                        }
                    }
            )
    }
}

struct SearchDrawerHandle: View {
    var body: some View {
        Capsule()
            .fill(.secondary.opacity(0.45))
            .frame(width: 42, height: 5)
            .padding(.top, 9)
            .padding(.bottom, 10)
            .accessibilityHidden(true)
    }
}

struct SearchLocationBar: View {
    @Binding var text: String
    let onSearch: () -> Void
    var onFocus: () -> Void = {}
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("My location", text: $text)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.search)
                    .onSubmit(onSearch)
                    .focused($isFocused)
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(.background.opacity(0.88), in: RoundedRectangle(cornerRadius: 13))
            .overlay {
                RoundedRectangle(cornerRadius: 13)
                    .stroke(.secondary.opacity(0.2))
            }

            Button("Search", action: onSearch)
                .buttonStyle(.bordered)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .onChange(of: isFocused) { _, focused in
            if focused { onFocus() }
        }
    }
}

struct SearchPreferenceSections: View {
    let maximumWalkingMinutes: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            preferenceCard(
                "Restaurant preferences",
                rows: [
                    ("Cuisine", "All", "fork.knife"),
                    ("Restaurants", "All", "building.2"),
                    ("Maximum walk", "\(maximumWalkingMinutes) minutes", "figure.walk")
                ]
            )
            preferenceCard(
                "Charging needs",
                rows: [
                    ("Connector", "All", "powerplug"),
                    ("Network", "All", "network"),
                    ("Speed", "150+ kW", "bolt.fill")
                ]
            )
        }
    }

    private func preferenceCard(
        _ title: LocalizedStringKey,
        rows: [(LocalizedStringKey, String, String)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 8)

            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                preferenceRow(row.0, value: row.1, systemImage: row.2)
                if index < rows.count - 1 {
                    Divider().padding(.leading, 32)
                }
            }
        }
        .padding(14)
        .background(.background.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
    }

    private func preferenceRow(
        _ title: LocalizedStringKey,
        value: String,
        systemImage: String
    ) -> some View {
        Button {} label: {
            HStack(spacing: 12) {
                Label(title, systemImage: systemImage)
                    .foregroundStyle(.primary)
                Spacer()
                Text(value)
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

struct PlaceSearchPanel: View {
    @Binding var query: String
    let suggestions: [LocationSearchSuggestion]
    let onCancel: () -> Void
    let onSelect: (LocationSearchSuggestion) -> Void
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    HStack(spacing: 9) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search places", text: $query)
                            .textInputAutocapitalization(.words)
                            .submitLabel(.search)
                            .focused($isSearchFocused)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 44)
                    .background(.background.opacity(0.88), in: RoundedRectangle(cornerRadius: 13))

                    Button("Cancel", action: onCancel)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    PlaceSearchDiscoveryContent(onSelect: onSelect)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(suggestions) { suggestion in
                            PlaceSuggestionRow(suggestion: suggestion) {
                                onSelect(suggestion)
                            }
                            Divider().padding(.leading, 54)
                        }
                    }
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .task {
            isSearchFocused = true
        }
    }
}

private struct PlaceSuggestionRow: View {
    let suggestion: LocationSearchSuggestion
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(.blue)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 3) {
                    Text(suggestion.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    if !suggestion.subtitle.isEmpty {
                        Text(suggestion.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct PlaceSearchDiscoveryContent: View {
    let onSelect: (LocationSearchSuggestion) -> Void

    private let recentSearches = [
        LocationSearchSuggestion(title: "Richmond, VA", subtitle: "Virginia, United States"),
        LocationSearchSuggestion(title: "New Haven, CT", subtitle: "Connecticut, United States"),
        LocationSearchSuggestion(title: "New York, NY", subtitle: "New York, United States"),
        LocationSearchSuggestion(title: "Baltimore Inner Harbor", subtitle: "Baltimore, Maryland"),
        LocationSearchSuggestion(title: "Princeton, NJ", subtitle: "New Jersey, United States"),
        LocationSearchSuggestion(title: "Philadelphia, PA", subtitle: "Pennsylvania, United States"),
        LocationSearchSuggestion(title: "Washington, DC", subtitle: "District of Columbia"),
        LocationSearchSuggestion(title: "Wilmington, DE", subtitle: "Delaware, United States")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
                HStack(spacing: 12) {
                    Button {
                        onSelect(LocationSearchSuggestion(title: "Home", subtitle: "Saved location"))
                    } label: {
                        Label("Home", systemImage: "house.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {} label: {
                        Label("Add", systemImage: "plus")
                            .font(.headline)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Add a common location")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Recents").font(.title2.bold())
                    ScrollView(.horizontal) {
                        LazyHStack(alignment: .top, spacing: 12) {
                            ForEach(Array(recentSearches.chunked(into: 4).enumerated()), id: \.offset) { _, page in
                                VStack(spacing: 0) {
                                    ForEach(page) { recent in
                                        PlaceSuggestionRow(suggestion: recent) { onSelect(recent) }
                                    }
                                }
                                .frame(width: 320)
                                .background(.background.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Restaurants").font(.title2.bold())
                    ScrollView(.horizontal) {
                        HStack(spacing: 10) {
                            Label("The Local Table", systemImage: "fork.knife")
                            Label("Green Leaf Kitchen", systemImage: "leaf.fill")
                            Label("Taco Junction", systemImage: "takeoutbag.and.cup.and.straw.fill")
                        }
                        .padding(.vertical, 8)
                    }
                    .scrollIndicators(.hidden)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Cuisines").font(.title2.bold())
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(["American", "Italian", "Mexican", "Asian", "Indian"], id: \.self) { cuisine in
                                Button(cuisine) {}
                                    .buttonStyle(.bordered)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }
        }
        .padding(16)
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { start in
            Array(self[start..<Swift.min(start + size, count)])
        }
    }
}

struct SelectedDestinationPanel: View {
    let subtitle: String?
    let distance: String
    let driveTime: String
    let maximumWalkingMinutes: Int
    let onRoute: () -> Void
    let onNearbyChargers: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(distance)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button(action: onRoute) {
                        Label(driveTime, systemImage: "car.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Nearby Chargers", action: onNearbyChargers)
                        .buttonStyle(.bordered)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Target Stop Window")
                        .font(.headline)
                    Text("100–150 miles applied")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(.background.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))

                SearchPreferenceSections(maximumWalkingMinutes: maximumWalkingMinutes)
            }
            .padding(16)
        }
    }
}
