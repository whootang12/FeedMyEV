import MapKit
import SwiftUI
import SwiftData

struct FindMyStopView: View {
    @Query private var savedStops: [SavedStop]
    @StateObject private var service = RouteStopService()
    @StateObject private var locationService = LocationService()
    @AppStorage("route.origin") private var origin = ""
    @Binding var destination: String
    @AppStorage("route.windowUnit") private var unit: StopWindowUnit = .minutes
    @AppStorage("route.windowLower") private var lower = 60.0
    @AppStorage("route.windowUpper") private var upper = 120.0
    @AppStorage("route.maximumDetour") private var maximumDetour = 20.0
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var searchTask: Task<Void, Never>?
    let onResults: (RouteStopResults) -> Void


    var body: some View {
        Form {
                Section("Your drive") {
                    TextField("From: Current location", text: $origin)
                        .textInputAutocapitalization(.words)
                    Button {
                        origin = ""
                        locationService.clearError()
                        locationService.requestCurrentLocation()
                    } label: {
                        Label(locationService.location == nil || !origin.isEmpty ? "Use my location" : "Current location ready", systemImage: "location.fill")
                    }
                    if let error = locationService.errorMessage {
                        Text(error).font(.caption).foregroundStyle(.red)
                    }
                    TextField("Destination town or address", text: $destination)
                        .textInputAutocapitalization(.words)
                }
                .disabled(isSearching)

                Section {
                    DisclosureGroup("Stop in \(Int(lower))–\(Int(upper)) \(unit.rawValue.lowercased()) · Max detour \(Int(maximumDetour)) min") {
                    Picker("Measure ahead in", selection: $unit) {
                        ForEach(StopWindowUnit.allCases) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                    Stepper("From \(Int(lower)) \(unit.rawValue.lowercased())", value: $lower, in: 0...350, step: 10)
                        .onChange(of: lower) { _, value in if upper <= value { upper = value + 10 } }
                    Stepper("To \(Int(upper)) \(unit.rawValue.lowercased())", value: $upper, in: (lower + 10)...360, step: 10)
                    Picker("Maximum added detour", selection: $maximumDetour) {
                        ForEach([10.0, 20.0, 30.0, 45.0], id: \.self) { value in
                            Text("\(Int(value)) minutes").tag(value)
                        }
                    }
                    }
                } header: {
                    Text("Find a stop ahead")
                } footer: {
                    Text("The window measures driving time or distance from your starting point to the charger. Food is available after selecting a stop. Charger power and connector compatibility are not yet verified.")
                }
                .disabled(isSearching)

                if let errorMessage {
                    Section { Text(errorMessage).foregroundStyle(.red) }
                }

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
