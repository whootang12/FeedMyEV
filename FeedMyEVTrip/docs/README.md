# Feed My EV Trip

Find a useful EV charging stop along a drive, within a chosen time or distance window, with nearby food that matches personal preferences.

This is a personal app for road-trip testing. Apple MapKit handles maps, place lookup, driving routes, food search, and navigation. Charger discovery uses a bundled U.S. Department of Energy [AFDC](https://afdc.energy.gov/data_download) catalog of public DC-fast stations.

## Open the project

Open `FeedMyEVTrip.xcodeproj` in Xcode and run the **FeedMyEVTrip** scheme. The app supports iPhone, iPad, Mac, and visionOS.

Location access is used to find chargers and nearby food. Refreshing the charger catalog uses a personal AFDC API key entered in **Preferences → Charger Data**. That key stays in the device Keychain and is not stored in this repository.

## Repository layout

- `FeedMyEVTrip/` — SwiftUI app. Xcode treats this folder as a synchronized group.
- `FeedMyEVTrip/docs/` — project notes, visible in Xcode and excluded from the app target.
- `Tests/` — standalone AFDC catalog checks, run from the command line.

## Documentation

- [MVP status](MVP_STATUS.md)
- [Feature requirements](requirements/README.md)
- [AFDC charger catalog](AFDC_DATA.md)
- [AI working preferences](CODEX.md)

## Catalog checks

From the repository root:

```sh
swiftc FeedMyEVTrip/Models/AFDCStation.swift FeedMyEVTrip/Models/ChargerConnector.swift Tests/AFDCCatalogChecks.swift -o /tmp/afdc-catalog-checks
/tmp/afdc-catalog-checks Tests/afdc-sample.json
```

## Data

Station data comes from the Alternative Fuels Data Center. AFDC supplies data as-is. Naming the source does not imply DOE or laboratory endorsement. Terms are on the [download page](https://afdc.energy.gov/data_download).
