# AFDC charger catalog

The app uses the U.S. Department of Energy Alternative Fuels Data Center (AFDC) station catalog for charger discovery. Apple MapKit remains responsible for maps, place lookup, driving routes, food search, and navigation.

## Search behavior

- A bundled snapshot provides U.S. public, available DC-fast stations immediately. No API key or charger-discovery request is needed for the initial catalog.
- Nearby searches filter the local catalog to the visible map region. Route searches select catalog stations near the relevant route segment before checking driving estimates with MapKit.
- Preferences for CCS, NACS, and CHAdeMO keep a stop when it lists at least one selected connector. Stations with none of those connector codes stay visible.
- Saved stations preserve AFDC IDs separately from Apple place IDs. Older saved stops can match by location.
- AFDC includes station-level connector types, network names, and DC-fast port counts. These do not guarantee 150+ kW, vehicle access, or real-time availability.

## Refresh and storage

- The catalog refresh interval is 30 days. Refresh is checked on demand, not at app launch.
- Preferences → Charger Data displays the station count and download date and provides a manual refresh.
- Get a personal API key from https://developer.nlr.gov/signup/ and enter it in Charger Data to enable refreshes. The key is stored in the device Keychain and sent in the API request header, never bundled in source control.
- Automatic refresh failures retain the old catalog with a warning. Automatic attempts are limited to once per hour while an old catalog remains available. Manual refresh can retry immediately.
- Concurrent refresh callers share one download. The whole response is validated before an atomic replacement. A truncated or empty catalog never replaces a working snapshot.
- The local snapshot contains only the station fields used by this app. Newer bundled snapshots take precedence over older downloaded snapshots.
- This retention policy applies to AFDC data, not Apple Maps data or traffic-sensitive driving estimates.

## Sources and limitations

Data source: https://afdc.energy.gov/data_download

Data format: https://afdc.energy.gov/data_download/alt_fuel_stations_format

API: https://developer.nlr.gov/docs/transportation/alt-fuel-stations-v1/all/

AFDC supplies data as-is. Attribution identifies the source and does not imply DOE or laboratory endorsement. Data terms are available on the download page.

The current provider covers the U.S. only and excludes Level-1/Level-2-only stations. Driving requests still occur for candidate validation; AFDC removes charger-discovery searches, not all MapKit requests. Food matching and walking-route improvements remain separate MVP work.

## Decoder checks

From the repository root, compile and run the standalone fixture checks:

```sh
swiftc FeedMyEVTrip/Models/AFDCStation.swift FeedMyEVTrip/Models/ChargerConnector.swift Tests/AFDCCatalogChecks.swift -o /tmp/afdc-catalog-checks
/tmp/afdc-catalog-checks Tests/afdc-sample.json
```

These checks cover incomplete response rejection, real AFDC record decoding, connector labels, eligibility/coordinate validation, and duplicate IDs.
