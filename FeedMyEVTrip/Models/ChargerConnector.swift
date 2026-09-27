import Foundation

enum ChargerConnector: String, CaseIterable, Identifiable {
    case ccs = "J1772COMBO"
    case nacs = "TESLA"
    case chademo = "CHADEMO"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ccs: "CCS"
        case .nacs: "NACS"
        case .chademo: "CHAdeMO"
        }
    }

    var storageKey: String { "charger.connector.\(rawValue)" }

    static func allows(_ connectorCodes: some Sequence<String>, defaults: UserDefaults = .standard) -> Bool {
        let present = Set(connectorCodes.compactMap(ChargerConnector.init(rawValue:)))
        guard !present.isEmpty else { return true }
        let selected = Set(allCases.filter { defaults.object(forKey: $0.storageKey) as? Bool ?? true })
        return !present.isDisjoint(with: selected)
    }
}
