import SwiftUI

struct ChargerDataView: View {
    @ObservedObject private var provider = AFDCChargerProvider.shared
    @State private var apiKey = ""
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                LabeledContent("Source", value: "AFDC")
                LabeledContent("Stations", value: provider.stationCount.formatted())
                if let date = provider.downloadedAt {
                    LabeledContent("Downloaded", value: date.formatted(date: .abbreviated, time: .omitted))
                }
                if let warning = provider.warning { Text(warning).foregroundStyle(.orange) }
                if provider.isRefreshing { ProgressView("Downloading charger catalog…") }
                Button("Refresh catalog") { download(saveKey: false) }
                    .disabled(!provider.hasAPIKey || provider.isRefreshing)
            } header: {
                Text("U.S. public DC-fast chargers")
            } footer: {
                Text("A starter catalog is included with the app and searched on your phone. With an API key, it refreshes on the next search after 30 days. An older download remains usable if a refresh fails. This is a station catalog, not live charger availability.")
            }

            Section {
                SecureField(provider.hasAPIKey ? "Replace API key" : "AFDC API key", text: $apiKey)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                Button("Save key and download") { download(saveKey: true) }
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || provider.isRefreshing)
                Link("Get a free API key", destination: URL(string: "https://developer.nlr.gov/signup/")!)
            } header: { Text("Catalog access") }
              footer: { Text("Your key is stored securely on this device. It is not included in the app’s source code.") }

            if let errorMessage { Section { Text(errorMessage).foregroundStyle(.red) } }
            Section {
                Link("AFDC station data", destination: URL(string: "https://afdc.energy.gov/data_download")!)
                Text("Connector types are station-level information. DC fast does not guarantee 150+ kW or compatibility with your vehicle. Check access and charging details before travel.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Charger Data")
    }

    private func download(saveKey: Bool) {
        errorMessage = nil
        Task {
            do {
                if saveKey { try provider.saveKey(apiKey); apiKey = "" }
                try await provider.refresh()
            } catch {
                errorMessage = (error as? AFDCCatalogError)?.localizedDescription ?? "Download failed. Check your connection and try again. Any previous catalog has been kept."
            }
        }
    }
}
