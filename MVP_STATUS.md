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
- Route-based charger discovery, driving estimates, and detour checks.
- Results ordered by added detour, with arrival time and distance.
- Route display with start/destination icons and an approximate stop-window highlight.
- Editable search inputs and return from charger details to the results map.
- Nearby-place searches and map-area re-searching.

### Chargers and food

- Charger selection from map pins or the results list.
- Nearby restaurant, café, and bakery discovery after selecting a charger.
- Persistent food-category and maximum-walking-time preferences.
- Food details with available address, phone, website, and links to Apple Maps, Google Maps, and Yelp.
- Charger/food map focus and Apple Maps driving navigation.

### Saved stops

- Local persistence of saved chargers, save date, location, and nearby food names.
- Saved List/Map views, newest-first list order, removal, and directions.
- Details pages accessible from the saved list and map.
- Saved chargers included as route-search candidates and checked against the stop window and detour allowance.
- Distinct bookmark icons and labels for saved chargers in search results.

### Search infrastructure

- Seven-day persistent place caching.
- Search cancellation, throttling retries, and error handling.
- Partial-result notices when some route searches or driving estimates fail.

## Remaining for the MVP

| Area | Remaining work |
| --- | --- |
| Charger data and preferences | Add reliable power and connector data, persistent charger preferences, and filtering for compatible 150+ kW chargers. Establish a provider interface so charger data sources can be changed independently. |
| Personalized food preferences | Save preferred restaurant chains and cuisines and use them in food searches. |
| Food-aware stop recommendations | Check food matches before presenting recommended stops. Currently, food is loaded only after selecting a charger. |
| Walking directions | Replace straight-line distance/time estimates with actual walking routes and travel times; apply the walking limit to those routes. |
| Favorite notes and tags | Add editable, persistent notes and tags to saved chargers. |
| Real-world validation | Test familiar routes and on-device use, charger coverage, detour accuracy, saved-stop inclusion, walking access, search throttling, cancellation, and the redesigned search panel. |
| Cache | Speed this up and prevent repeated searches
| Automated Testing | Test cases for each

## Current limitations

- Charger results do not yet verify charging power or connector compatibility.
- Route discovery samples areas and limits checks of newly discovered chargers; it is not an exhaustive charger catalog. Saved candidates bypass that discovery cap, but failed requests can still leave results incomplete.
- The highlighted time-based stop segment is approximate. Candidate acceptance uses calculated driving estimates.
- Driving estimates can change. Detours exclude charging and meal time.
- Walking times are straight-line estimates rather than verified pedestrian routes.
- Saved food names are a snapshot from when a charger was saved.

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
4. Favorite notes/tags and real-world validation before calling the MVP complete.
