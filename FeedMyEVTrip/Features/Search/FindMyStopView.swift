import MapKit
import SwiftUI
import SwiftData

struct FindMyStopView: View {
    private enum RouteTab: CaseIterable, Identifiable {
        case driving, restaurants, charging

        var id: Self { self }
        var systemImage: String {
            switch self {
            case .driving: "car.fill"
            case .restaurants: "fork.knife"
            case .charging: "bolt.fill"
            }
        }
        var accessibilityTitle: LocalizedStringKey {
            switch self {
            case .driving: "Driving"
            case .restaurants: "Restaurant preferences"
            case .charging: "Charging needs"
            }
        }
    }

    @Query private var savedStops: [SavedStop]
    @StateObject private var service = RouteStopService()
    @StateObject private var locationService = LocationService()
    @AppStorage("route.origin") private var origin = ""
    @Binding var destination: String
    @AppStorage("route.windowUnit") private var unit: StopWindowUnit = .miles
    @AppStorage("route.windowLower") private var lower = 100.0
    @AppStorage("route.windowUpper") private var upper = 150.0
    @AppStorage("route.maximumDetour") private var maximumDetour = 20.0
    @AppStorage(FoodPreferenceKeys.maximumWalkingMinutes) private var maximumWalkingMinutes = 15
    @State private var selectedTab = RouteTab.driving
    @State private var isStopWindowExpanded = false
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var searchTask: Task<Void, Never>?
    let onResults: (RouteStopResults) -> Void


    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                routeTabs

                switch selectedTab {
                case .driving:
                    drivingContent
                case .restaurants:
                    VStack(spacing: 14) {
                        preferenceCard(
                            title: "Restaurant preferences",
                            rows: [("Cuisine", "All"), ("Restaurants", "All")]
                        )
                        walkingCard
                    }
                case .charging:
                    preferenceCard(
                        title: "Charging needs",
                        rows: [("Connector", "All"), ("Network", "All"), ("Speed", "150+ kW")]
                    )
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
            .padding(16)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 8) {
                if isSearching {
                    ProgressView(service.progress)
                    Button("Cancel search") { cancel(); isSearching = false }
                } else {
                    Button(action: search) {
                        Label("Search", systemImage: "magnifyingglass")
                            .font(.headline).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              (origin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && locationService.location == nil))
                }
            }
            .padding().background(.regularMaterial)
        }
        .onDisappear(perform: cancel)
    }

    private var routeTabs: some View {
        HStack(spacing: 8) {
            ForEach(RouteTab.allCases) { tab in
                Button {
                    withAnimation(.snappy) { selectedTab = tab }
                } label: {
                    Image(systemName: tab.systemImage)
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(selectedTab == tab ? .white : .primary)
                .background(selectedTab == tab ? Color.blue : Color.clear, in: Capsule())
                .accessibilityLabel(tab.accessibilityTitle)
                .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
            }
        }
        .padding(5)
        .background(.secondary.opacity(0.12), in: Capsule())
    }

    private var drivingContent: some View {
        VStack(spacing: 14) {
            routeField(
                text: $origin,
                prompt: "My location",
                color: origin.isEmpty ? .blue : .green,
                accessibilityLabel: "Route start"
            )
            routeField(
                text: $destination,
                prompt: "Destination",
                color: .red,
                accessibilityLabel: "Route destination"
            )

            if let error = locationService.errorMessage {
                Text(error).font(.caption).foregroundStyle(.red)
            }

            DisclosureGroup(isExpanded: $isStopWindowExpanded) {
                VStack(alignment: .leading, spacing: 14) {
                    Picker("Range unit", selection: $unit) {
                        Text("Miles").tag(StopWindowUnit.miles)
                        Text("Hours").tag(StopWindowUnit.minutes)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: unit) { _, newUnit in
                        if newUnit == .miles {
                            lower = 100
                            upper = 150
                        } else {
                            lower = 90
                            upper = 150
                        }
                    }

                    rangeRow(title: "From", value: $lower)
                    rangeRow(title: "To", value: $upper)

                    Picker("Maximum added detour", selection: $maximumDetour) {
                        ForEach([10.0, 20.0, 30.0, 45.0], id: \.self) { value in
                            Text("\(Int(value)) minutes").tag(value)
                        }
                    }
                }
                .padding(.top, 12)
            } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Target Stop Window").font(.headline)
                    Text(stopWindowSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .background(.background.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
            .disabled(isSearching)
        }
    }

    private var walkingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How far are you willing to walk?").font(.headline)
            Picker("Maximum walking time", selection: $maximumWalkingMinutes) {
                ForEach([5, 10, 15, 20], id: \.self) { minutes in
                    Text("\(minutes) min").tag(minutes)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(14)
        .background(.background.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
    }

    private func routeField(
        text: Binding<String>,
        prompt: LocalizedStringKey,
        color: Color,
        accessibilityLabel: LocalizedStringKey
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "circle.fill")
                .foregroundStyle(color)
                .accessibilityLabel(accessibilityLabel)
            TextField(prompt, text: text)
                .textInputAutocapitalization(.words)
                .font(.body.weight(.semibold))
        }
        .padding(14)
        .background(.background.opacity(0.86), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14).stroke(.secondary.opacity(0.2))
        }
        .disabled(isSearching)
    }

    private func rangeRow(title: LocalizedStringKey, value: Binding<Double>) -> some View {
        HStack {
            Text(title).font(.headline).frame(width: 48, alignment: .leading)
            Button {
                value.wrappedValue = max(rangeIncrement, value.wrappedValue - rangeIncrement)
            } label: { Image(systemName: "minus") }
                .buttonStyle(.bordered)

            Text(formattedRangeValue(value.wrappedValue))
                .monospacedDigit()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

            Button { value.wrappedValue += rangeIncrement } label: { Image(systemName: "plus") }
                .buttonStyle(.bordered)
        }
    }

    private func preferenceCard(
        title: LocalizedStringKey,
        rows: [(LocalizedStringKey, LocalizedStringKey)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).font(.headline).padding(.bottom, 8)
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                Button {} label: {
                    HStack {
                        Text(row.0).foregroundStyle(.primary)
                        Spacer()
                        Text(row.1).foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                if index < rows.count - 1 { Divider() }
            }
        }
        .padding(14)
        .background(.background.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
    }

    private var rangeIncrement: Double { unit == .miles ? 25 : 30 }

    private var stopWindowSummary: String {
        if unit == .miles {
            return "\(Int(lower))–\(Int(upper)) miles applied"
        }
        return "\(formattedRangeValue(lower))–\(formattedRangeValue(upper)) hours applied"
    }

    private func formattedRangeValue(_ value: Double) -> String {
        if unit == .miles { return value.formatted(.number.precision(.fractionLength(0))) }
        return (value / 60).formatted(.number.precision(.fractionLength(1)))
    }

    private func search() {
        isSearching = true
        errorMessage = nil
        searchTask = Task {
            do {
                let result = try await service.find(
                    originQuery: origin.trimmingCharacters(in: .whitespacesAndNewlines),
                    location: locationService.location,
                    destinationQuery: destination.trimmingCharacters(in: .whitespacesAndNewlines),
                    window: StopWindow(unit: unit, lower: lower, upper: upper),
                    maximumDetour: maximumDetour,
                    savedChargers: savedStops.map { ChargerResult(savedStop: $0) }
                )
                try Task.checkCancellation()
                onResults(result)
            } catch {
                guard !Task.isCancelled else { return }
                switch error {
                case let failure as AFDCCatalogError:
                    errorMessage = failure.localizedDescription
                case MapSearchFailure.throttled:
                    errorMessage = "Apple Maps is limiting requests. Please wait a moment and try again."
                case MapSearchFailure.networkUnavailable:
                    errorMessage = "Check your internet connection and try again."
                case let failure as RouteFailure:
                    errorMessage = failure.localizedDescription
                default:
                    errorMessage = "The route search couldn’t finish. Check your connection and try again."
                }
            }
            isSearching = false
        }
    }

    private func cancel() {
        searchTask?.cancel()
        service.cancel()
    }
}
