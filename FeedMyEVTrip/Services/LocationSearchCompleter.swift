import Combine
import MapKit

struct LocationSearchSuggestion: Identifiable, Equatable {
    let title: String
    let subtitle: String
    /// The MapKit completion this suggestion came from. Resolving it directly
    /// returns the place the person chose instead of re-searching the text.
    var completion: MKLocalSearchCompletion? = nil

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
        // MKLocalSearchCompleter calls its delegate on the main thread.
        MainActor.assumeIsolated {
            self.suggestions = completer.results.prefix(12).map {
                LocationSearchSuggestion(title: $0.title, subtitle: $0.subtitle, completion: $0)
            }
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            suggestions = []
        }
    }
}
