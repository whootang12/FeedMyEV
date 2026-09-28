import Combine
import MapKit

struct LocationSearchSuggestion: Identifiable, Equatable {
    let title: String
    let subtitle: String

    var id: String { "\(title)|\(subtitle)" }
    var query: String { subtitle.isEmpty ? title : "\(title), \(subtitle)" }
}

@MainActor
final class LocationSearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published private(set) var suggestions: [LocationSearchSuggestion] = []

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func update(query: String, region: MKCoordinateRegion?) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            suggestions = []
            completer.queryFragment = ""
            return
        }
        if let region {
            completer.region = region
        }
        completer.queryFragment = trimmedQuery
    }

    func clear() {
        completer.queryFragment = ""
        suggestions = []
    }

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let suggestions = completer.results.prefix(12).map {
            LocationSearchSuggestion(title: $0.title, subtitle: $0.subtitle)
        }
        Task { @MainActor in
            self.suggestions = suggestions
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            suggestions = []
        }
    }
}
