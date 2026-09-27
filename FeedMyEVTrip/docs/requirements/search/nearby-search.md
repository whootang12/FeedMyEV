# Nearby search

Status: Implemented

Code: `FeedMyEVTrip/Features/Search/SearchView.swift`, `FeedMyEVTrip/Services/AFDCChargerProvider.swift`

The map opens with no charger results. **Near a place** searches the local AFDC catalog inside the visible map region, then applies connector preferences.

## Requirements

### R1. Empty start

The Search tab opens on the map with no charger results loaded.

### R2. Region filter

A charger is inside the searched region when its latitude is within half the region’s latitude span of the center, and its longitude is within half the longitude span after normalizing the difference across the antimeridian.

### R3. Connector filter

After the region filter, only chargers allowed by [connector preferences](../chargers/connector-preferences.md) remain.

### R4. Empty results

When the region contains no catalog chargers, the message is “No chargers found near {place}.” When the region contains chargers and every one is removed by connector preferences, the message says none match the connector preferences.

### R5. Result count

When at least one charger remains, the message reports that count.

### R6. Search this area

Re-searching the visible map is available for nearby mode when no route results, charger, or in-progress search is showing. It replaces the current charger list with the new region’s matches.

### R7. Cancellation

Cancelling an in-progress nearby search leaves the previous results in place and does not show an error.

## Test cases

| ID | Covers | Type | Given | When | Then |
| --- | --- | --- | --- | --- | --- |
| TC1 | R2 | Unit | A region centered at latitude 40, longitude -74, with span 2 by 2 | A charger at 40.9, -74.9 is tested | It is inside the region |
| TC2 | R2 | Unit | The same region | A charger at 41.1, -74 is tested | It is outside the region |
| TC3 | R2 | Unit | A region centered at longitude 179 with a span that crosses 180 | A charger at longitude -179 inside that span is tested | It is inside the region |
| TC4 | R3 | Unit | NACS is off and CCS is on | A Tesla-only station is in the region | It is removed |
| TC5 | R4 | Unit | The region catalog is empty | Nearby search finishes | The message names the place and does not mention connector preferences |
| TC6 | R4 | Unit | The region has only NACS stations and NACS is off | Nearby search finishes | The message says no chargers match connector preferences |
| TC7 | R5 | Unit | Three chargers remain after filtering | Nearby search finishes | The message includes the count 3 |
| TC8 | R6 | Integration | Nearby results are already showing | The map moves and Search this area is used | The list matches the new region and the old list is replaced |
| TC9 | R7 | Integration | A nearby search is running | The search is cancelled | No error is shown for the cancellation |

## Later unit-test notes

Extract the region test from `AFDCChargerProvider.chargers(in:)` so TC1–TC3 do not need MapKit search. Connector cases can call `ChargerConnector.allows`.
