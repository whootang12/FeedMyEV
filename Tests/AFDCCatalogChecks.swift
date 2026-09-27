import Foundation

@main
struct AFDCCatalogChecks {
    static func main() throws {
let sample = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
do {
    _ = try AFDCPayload.decodeComplete(sample)
    fatalError("Truncated catalog should be rejected")
} catch AFDCCatalogError.incomplete { }
var payload = try JSONSerialization.jsonObject(with: sample) as! [String: Any]
var records = payload["fuel_stations"] as! [[String: Any]]
payload["total_results"] = records.count
let valid = try AFDCPayload.decodeComplete(JSONSerialization.data(withJSONObject: payload))
precondition(valid.count == 2)
precondition(valid[0].connectorNames.contains("CCS"))
precondition(valid[0].connectorNames.contains("J1772 AC"))
var invalid = records[0]
invalid["status_code"] = "P"
records.append(invalid)
invalid["status_code"] = "E"
invalid["latitude"] = 999
records.append(invalid)
records.append(records[0])
payload["fuel_stations"] = records
payload["total_results"] = records.count
let filtered = try AFDCPayload.decodeComplete(JSONSerialization.data(withJSONObject: payload))
precondition(filtered.count == 2, "Planned, invalid coordinates and duplicate IDs must be excluded")

print("AFDC catalog checks passed")
    }
}
