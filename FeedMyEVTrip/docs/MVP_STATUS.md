# Feed My EV Trip — MVP Status

Updated: September 26, 2026

## Goal

Find a useful EV charging stop along a drive, within a chosen time or distance window, with compatible fast charging and nearby food that matches personal preferences. The first release is for personal road-trip testing.

## Built

### Search and route planning

- Map-first interface that opens without charger results.
- One expandable bottom panel for search, vertical results, and charger details.
- Explicit **Along a route** and **Near a place** search modes.
- Starting-place and destination entry, plus current-location support.
- Stop windows in minutes or miles, with a maximum added driving detour.
- Route-based charger discovery from a local AFDC catalog, driving estimates, and detour checks.
- Results ordered by added detour, with arrival time and distance.
- Route display with start/destination icons and an approximate stop-window highlight.
- Editable search inputs and return from charger details to the results map.
- Nearby-place searches and map-area re-searching.



### Chargers and food

- Charger selection from map pins or the results list.
- Nearby restaurant, café, and bakery discovery after selecting a charger.
- Persistent food-category and maximum-walking-time preferences.
- Persistent CCS, NACS, and CHAdeMO preferences, applied to nearby and route searches.
- Food details with available address, phone, website, and links to Apple Maps, Google Maps, and Yelp.
- Saved restaurant chains and specific locations, with one note per location.
- Nearby food lists saved chains ahead of other places within walking range.
- Charger/food map focus and Apple Maps driving navigation.



### Saved stops

- Local persistence of saved chargers, save date, location, nearby food names, and one note.
- Saved List/Map views, newest-first list order, removal, and directions.
- Details pages accessible from the saved list and map. Each saved nearby restaurant opens food details.
- Saved chargers included as route-search candidates and checked against the stop window and detour allowance.
- Distinct bookmark icons and labels for saved chargers in search results.



### Search infrastructure

- Bundled AFDC U.S. public DC-fast catalog with local charger discovery and a 30-day refresh interval.
- Secure API-key setup, manual catalog refresh, and older-catalog fallback in Preferences → Charger Data.
- Seven-day Apple place caching remains separate; its retention policy still needs review against Apple’s terms.
- Search cancellation, throttling retries, and error handling.
- Partial-result notices when some route searches or driving estimates fail.



## Remaining for the MVP


| Area                            | Remaining work                                                                                                                                                                                                                                            |
| ------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Charger data and preferences    | AFDC provider interface, station IDs, connector metadata, network names, DC-fast port counts, and CCS/NACS/CHAdeMO preferences are built. Add reliable power verification, vehicle/access compatibility beyond connector type, and filtering for compatible 150+ kW chargers. |
| Personalized food preferences   | Saved chains are stored and preferred in nearby food. Add cuisines, and a way to search for a saved chain by name.                                                                                                                                         |
| Food-aware stop recommendations | Check food matches before presenting recommended stops. Currently, food is loaded only after selecting a charger.                                                                                                                                         |
| Walking directions              | Replace straight-line distance/time estimates with actual walking routes and travel times; apply the walking limit to those routes.                                                                                                                       |
| Favorite notes and tags         | Charger and restaurant-location notes are saved. Add tags on saved chargers.                                                                                                                                                                               |
| Real-world validation           | Test familiar routes and on-device use, charger coverage, detour accuracy, saved-stop inclusion, walking access, search throttling, cancellation, and the redesigned search panel.                                                                        |
| Cache                           | Speed this up and prevent repeated searches                                                                                                                                                                                                               |
| Automated Testing               | Requirements and test-case IDs are in `docs/requirements/`. Write unit tests from those IDs.                                                                                                                                                             |
| Type Ahead Searching            | Where a location is searched, support type ahead




## Current limitations

- Charger results filter by the selected CCS, NACS, and CHAdeMO connectors. They do not yet verify charging power.
- Route discovery uses the local AFDC catalog and an approximate route corridor, then limits driving checks of newly discovered candidates. Saved candidates bypass that cap; failed driving requests can still leave results incomplete.
- The highlighted time-based stop segment is approximate. Candidate acceptance uses calculated driving estimates.
- Driving estimates can change. Detours exclude charging and meal time.
- Walking times are straight-line estimates rather than verified pedestrian routes.
- Saved food names are a snapshot from when a charger was saved.
- A saved chain matches the restaurant’s place name. “Wawa #12” does not match a saved “Wawa.”



## Validation completed

- The app builds successfully after the implemented changes.
- Route-calculation checks cover time/distance boundaries, interpolation, clamping, corridor projection, and repeated route vertices.
- The redesigned initial search screen was visually checked in the iPhone simulator.
- Full live-route and road-trip validation is still outstanding; build success does not establish search coverage or real-world usability.



## Intentionally deferred

- StoreKit, payments, and paywalls.
- Been Here functionality and visit history.
- Advanced saved-stop sorting and filtering.
- Accounts, backend synchronization, and iCloud sync.
- Live charger availability/status.
- Battery state-of-charge and range prediction.
- CarPlay and full multi-stop trip planning.



## Suggested next steps

1. Reliable charger data and compatibility preferences.
2. Personalized food matching and real walking directions.
3. Food-aware route recommendations.
4. Charger tags and real-world validation before calling the MVP complete.

