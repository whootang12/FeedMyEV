import MapKit
import Combine
import Security

@MainActor
protocol ChargerProvider {
    func loadChargers() async throws -> [ChargerResult]
}

@MainActor
final class AFDCChargerProvider: ObservableObject, ChargerProvider {
    static let shared = AFDCChargerProvider()
    @Published private(set) var stationCount = 0
    @Published private(set) var downloadedAt: Date?
    @Published private(set) var isRefreshing = false
    @Published private(set) var warning: String?
    @Published private(set) var hasAPIKey = false
    private var stations: [AFDCStation] = []
    private var cachedChargers: [ChargerResult]?
    private var refreshTask: Task<Void, Error>?
    private var lastAttempt: Date?
    private let lifetime: TimeInterval = 30 * 24 * 60 * 60
    private let fileURL: URL

    private struct Snapshot: Codable {
        let version: Int
        let downloadedAt: Date
        let stations: [AFDCStation]
    }

    private init() {
        fileURL = URL.applicationSupportDirectory.appending(path: "afdc-public-dc-fast-v1.json")
        hasAPIKey = readKey() != nil
        let urls = [fileURL, Bundle.main.url(forResource: "afdc-public-dc-fast-v1", withExtension: "json")].compactMap { $0 }
        let snapshots = urls.compactMap { url -> Snapshot? in
            guard let data = try? Data(contentsOf: url),
                  let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data),
                  snapshot.version == 1, !snapshot.stations.isEmpty else { return nil }
            return snapshot
        }
        if let snapshot = snapshots.max(by: { $0.downloadedAt < $1.downloadedAt }) {
            stations = snapshot.stations.filter(\.isEligible)
            downloadedAt = snapshot.downloadedAt
            stationCount = stations.count
        }
    }

    var isStale: Bool {
        guard let downloadedAt else { return true }
        return Date().timeIntervalSince(downloadedAt) >= lifetime
    }

    func loadChargers() async throws -> [ChargerResult] {
        if stations.isEmpty || (isStale && (lastAttempt.map { Date().timeIntervalSince($0) > 3600 } ?? true)) {
            do { try await refresh() }
            catch {
                guard !stations.isEmpty else { throw error }
                warning = "Using the older AFDC download. Refresh failed; check Charger Data in Preferences."
            }
        }
        try Task.checkCancellation()
        if isStale && warning == nil { warning = "The AFDC catalog is over 30 days old. Refresh in Preferences → Charger Data." }
        if let cachedChargers { return cachedChargers }
        let chargers = stations.map(ChargerResult.init(station:))
        cachedChargers = chargers
        return chargers
    }

    func chargers(in region: MKCoordinateRegion) async throws -> [ChargerResult] {
        try await loadChargers().filter { charger in
            let coordinate = charger.coordinate
            let longitudeDifference = abs((coordinate.longitude - region.center.longitude + 540).truncatingRemainder(dividingBy: 360) - 180)
            return abs(coordinate.latitude - region.center.latitude) <= region.span.latitudeDelta / 2
                && longitudeDifference <= region.span.longitudeDelta / 2
        }
    }

    func refresh() async throws {
        if let refreshTask { return try await refreshTask.value }
        let task = Task { try await download() }
        refreshTask = task
        defer { refreshTask = nil }
        try await task.value
    }

    private func download() async throws {
        lastAttempt = Date()
        guard let key = readKey() else { throw AFDCCatalogError.missingKey }
        isRefreshing = true
        defer { isRefreshing = false }
        var components = URLComponents(string: "https://developer.nlr.gov/api/alt-fuel-stations/v1.json")!
        components.queryItems = [
            URLQueryItem(name: "fuel_type", value: "ELEC"),
            URLQueryItem(name: "country", value: "US"),
            URLQueryItem(name: "access", value: "public"),
            URLQueryItem(name: "status", value: "E"),
            URLQueryItem(name: "ev_charging_level", value: "dc_fast"),
            URLQueryItem(name: "limit", value: "all")
        ]
        var request = URLRequest(url: components.url!)
        request.setValue(key, forHTTPHeaderField: "X-Api-Key")
        request.timeoutInterval = 120
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw AFDCCatalogError.unavailable }
        switch response.statusCode {
        case 200: break
        case 401, 403: throw AFDCCatalogError.unauthorized
        case 429: throw AFDCCatalogError.rateLimited
        default: throw AFDCCatalogError.unavailable
        }
        let downloaded = try AFDCPayload.decodeComplete(data)
        let date = Date()
        let snapshot = Snapshot(version: 1, downloadedAt: date, stations: downloaded)
        let encoded = try JSONEncoder().encode(snapshot)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoded.write(to: fileURL, options: .atomic)
        stations = downloaded
        cachedChargers = nil
        stationCount = downloaded.count
        downloadedAt = date
        warning = nil
    }

    private var keyQuery: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: "com.colinwhooten.FeedMyEVTrip.afdc",
         kSecAttrAccount as String: "api-key"]
    }

    private func readKey() -> String? {
        var query = keyQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func saveKey(_ key: String) throws {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw AFDCCatalogError.missingKey }
        let data = Data(trimmed.utf8)
        var status = SecItemUpdate(keyQuery as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var query = keyQuery
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            status = SecItemAdd(query as CFDictionary, nil)
        }
        guard status == errSecSuccess else { throw AFDCCatalogError.keyStorage }
        hasAPIKey = true
        lastAttempt = nil
    }
}
