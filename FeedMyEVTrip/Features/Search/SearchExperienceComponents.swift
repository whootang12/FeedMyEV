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

/// Storage keys and defaults for the route stop window. The window defaults to
/// driving time (shown in hours, adjusted in half-hour steps).
enum RouteWindowSettings {
    static let unitKey = "route.windowUnit"
    static let lowerKey = "route.windowLower"
    static let upperKey = "route.windowUpper"
    static let defaultUnit = StopWindowUnit.minutes
    static let defaultLower = 90.0
    static let defaultUpper = 150.0

    private static let legacyCheckKey = "route.windowUnitDefaultChecked"

    /// Earlier versions defaulted to miles and stored only the bounds. On the
    /// first launch after the default changed to hours, record miles for those
    /// windows so they aren't reinterpreted. Runs once: afterwards an unstored
    /// unit means the hours default.
    static func preserveLegacyMilesWindow(in defaults: UserDefaults = .standard) {
        guard !defaults.bool(forKey: legacyCheckKey) else { return }
        defaults.set(true, forKey: legacyCheckKey)
        guard defaults.object(forKey: unitKey) == nil,
              defaults.object(forKey: lowerKey) != nil || defaults.object(forKey: upperKey) != nil
        else { return }
        defaults.set(StopWindowUnit.miles.rawValue, forKey: unitKey)
    }
}

/// Text for the saved search preferences, read from the same storage the
/// Preferences tab and route form write. Cuisine, network, and charging speed
/// are not filtered yet, so their rows say "Any" instead of implying a check.
struct SearchPreferenceValues: DynamicProperty {
    static let unfiltered = "Any"

    @AppStorage(FoodPreferenceKeys.includesRestaurants) private var includesRestaurants = true
    @AppStorage(FoodPreferenceKeys.includesCafes) private var includesCafes = true
    @AppStorage(FoodPreferenceKeys.includesBakeries) private var includesBakeries = true
    @AppStorage(ChargerConnector.ccs.storageKey) private var includesCCS = true
    @AppStorage(ChargerConnector.nacs.storageKey) private var includesNACS = true
    @AppStorage(ChargerConnector.chademo.storageKey) private var includesCHAdeMO = true
    @AppStorage(RouteWindowSettings.unitKey) private var windowUnit = RouteWindowSettings.defaultUnit
    @AppStorage(RouteWindowSettings.lowerKey) private var windowLower = RouteWindowSettings.defaultLower
    @AppStorage(RouteWindowSettings.upperKey) private var windowUpper = RouteWindowSettings.defaultUpper

    var foodTypes: String {
        Self.summary([("Restaurants", includesRestaurants), ("Cafés", includesCafes), ("Bakeries", includesBakeries)])
    }

    var connectors: String {
        Self.summary([
            (ChargerConnector.ccs.title, includesCCS),
            (ChargerConnector.nacs.title, includesNACS),
            (ChargerConnector.chademo.title, includesCHAdeMO)
        ])
    }

    var stopWindow: String {
        Self.stopWindowDescription(unit: windowUnit, lower: windowLower, upper: windowUpper)
    }

    static func stopWindowDescription(unit: StopWindowUnit, lower: Double, upper: Double) -> String {
        if unit == .miles {
            let format = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0))
            return "\(lower.formatted(format))–\(upper.formatted(format)) miles applied"
        }
        let format = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0...1))
        return "\((lower / 60).formatted(format))–\((upper / 60).formatted(format)) hours applied"
    }

    private static func summary(_ options: [(String, Bool)]) -> String {
        let selected = options.filter(\.1).map(\.0)
        return selected.count == options.count ? "All" : selected.joined(separator: ", ")
    }
}

struct SearchPreferenceSections: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RestaurantPreferencesCard()
            ChargingPreferencesCard()
        }
    }
}

/// Food preferences, editable in place. Uses the same storage as the Preferences tab.
struct RestaurantPreferencesCard: View {
    var includesWalking = true

    @AppStorage(FoodPreferenceKeys.includesRestaurants) private var includesRestaurants = true
    @AppStorage(FoodPreferenceKeys.includesCafes) private var includesCafes = true
    @AppStorage(FoodPreferenceKeys.includesBakeries) private var includesBakeries = true
    @AppStorage(FoodPreferenceKeys.maximumWalkingMinutes) private var maximumWalkingMinutes = 15
    private let values = SearchPreferenceValues()

    var body: some View {
        PreferenceCard(title: "Restaurant preferences") {
            PreferenceRowLabel(title: "Cuisine", value: SearchPreferenceValues.unfiltered, systemImage: "fork.knife")
            PreferenceDivider()
            Menu {
                // At least one food type stays selected, as in Preferences.
                Toggle("Restaurants", isOn: $includesRestaurants)
                    .disabled(includesRestaurants && !includesCafes && !includesBakeries)
                Toggle("Cafés", isOn: $includesCafes)
                    .disabled(includesCafes && !includesRestaurants && !includesBakeries)
                Toggle("Bakeries", isOn: $includesBakeries)
                    .disabled(includesBakeries && !includesRestaurants && !includesCafes)
            } label: {
                PreferenceRowLabel(title: "Food types", value: values.foodTypes, systemImage: "building.2", isEditable: true)
            }
            .buttonStyle(.plain)
            if includesWalking {
                PreferenceDivider()
                Menu {
                    Picker("Maximum walk", selection: $maximumWalkingMinutes) {
                        ForEach([5, 10, 15, 20], id: \.self) { Text("\($0) minutes").tag($0) }
                    }
                } label: {
                    PreferenceRowLabel(
                        title: "Maximum walk",
                        value: "\(maximumWalkingMinutes) minutes",
                        systemImage: "figure.walk",
                        isEditable: true
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Charging preferences, editable in place. Uses the same storage as the Preferences tab.
struct ChargingPreferencesCard: View {
    @AppStorage(ChargerConnector.ccs.storageKey) private var includesCCS = true
    @AppStorage(ChargerConnector.nacs.storageKey) private var includesNACS = true
    @AppStorage(ChargerConnector.chademo.storageKey) private var includesCHAdeMO = true
    private let values = SearchPreferenceValues()

    var body: some View {
        PreferenceCard(title: "Charging needs") {
            Menu {
                // At least one connector stays selected, as in Preferences.
                Toggle(ChargerConnector.ccs.title, isOn: $includesCCS)
                    .disabled(includesCCS && !includesNACS && !includesCHAdeMO)
                Toggle(ChargerConnector.nacs.title, isOn: $includesNACS)
                    .disabled(includesNACS && !includesCCS && !includesCHAdeMO)
                Toggle(ChargerConnector.chademo.title, isOn: $includesCHAdeMO)
                    .disabled(includesCHAdeMO && !includesCCS && !includesNACS)
            } label: {
                PreferenceRowLabel(title: "Connector", value: values.connectors, systemImage: "powerplug", isEditable: true)
            }
            .buttonStyle(.plain)
            PreferenceDivider()
            PreferenceRowLabel(title: "Network", value: SearchPreferenceValues.unfiltered, systemImage: "network")
            PreferenceDivider()
            PreferenceRowLabel(title: "Speed", value: SearchPreferenceValues.unfiltered, systemImage: "bolt.fill")
        }
    }
}

private struct PreferenceCard<Rows: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let rows: Rows

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 8)
            rows
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct PreferenceDivider: View {
    var body: some View { Divider().padding(.leading, 32) }
}

/// One preference row. Editable rows show a menu indicator; rows for filters
/// that don't exist yet are plain text.
private struct PreferenceRowLabel: View {
    let title: LocalizedStringKey
    let value: String
    let systemImage: String
    var isEditable = false

    var body: some View {
        HStack(spacing: 12) {
            Label(title, systemImage: systemImage)
                .foregroundStyle(.primary)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
            if isEditable {
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
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
    private let values = SearchPreferenceValues()
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
                    Text(values.stopWindow)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(.background.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))

                SearchPreferenceSections()
            }
            .padding(16)
        }
    }
}
