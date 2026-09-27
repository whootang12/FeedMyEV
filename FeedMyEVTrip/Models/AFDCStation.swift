import Foundation

struct AFDCStation: Codable, Identifiable {
    let id: Int
    let stationName: String
    let streetAddress: String?
    let city: String?
    let state: String?
    let zip: String?
    let country: String?
    let latitude: Double?
    let longitude: Double?
    let fuelTypeCode: String?
    let accessCode: String?
    let statusCode: String?
    let evDcFastNum: Int?
    let evConnectorTypes: [String]?
    let evNetwork: String?

    var isEligible: Bool {
        guard let latitude, let longitude, latitude.isFinite, longitude.isFinite,
              (-90...90).contains(latitude), (-180...180).contains(longitude) else { return false }
        return country == "US" && fuelTypeCode == "ELEC" && accessCode == "public"
            && statusCode == "E" && (evDcFastNum ?? 0) > 0
    }

    var address: String {
        [streetAddress, city, state, zip].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
    }

    var connectorNames: [String] {
        (evConnectorTypes ?? []).map {
            switch $0 {
            case "J1772COMBO": return "CCS"
            case "TESLA": return "NACS"
            case "CHADEMO": return "CHAdeMO"
            case "J1772": return "J1772 AC"
            default: return $0
            }
        }
    }

    var summary: String {
        [evNetwork, "\(evDcFastNum ?? 0) DC-fast ports", connectorNames.joined(separator: ", ")]
            .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
    }
}

struct AFDCPayload: Decodable {
    let totalResults: Int
    let fuelStations: [AFDCStation]

    static func decodeComplete(_ data: Data) throws -> [AFDCStation] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let payload = try decoder.decode(Self.self, from: data)
        guard payload.totalResults > 0, payload.totalResults == payload.fuelStations.count else {
            throw AFDCCatalogError.incomplete
        }
        var ids = Set<Int>()
        let stations = payload.fuelStations.filter { $0.isEligible && ids.insert($0.id).inserted }
        guard !stations.isEmpty else { throw AFDCCatalogError.incomplete }
        return stations
    }
}

enum AFDCCatalogError: LocalizedError {
    case missingKey, unauthorized, rateLimited, unavailable, incomplete, keyStorage
    var errorDescription: String? {
        switch self {
        case .missingKey: return "Set up your AFDC API key in Preferences → Charger Data before searching."
        case .unauthorized: return "AFDC rejected the API key. Update it in Preferences → Charger Data."
        case .rateLimited: return "AFDC is limiting downloads. Try again later."
        case .unavailable: return "The AFDC catalog couldn’t be downloaded. Check your connection and try again."
        case .incomplete: return "AFDC returned an incomplete catalog. Your previous download was kept."
        case .keyStorage: return "The API key couldn’t be saved securely. Please try again."
        }
    }
}
