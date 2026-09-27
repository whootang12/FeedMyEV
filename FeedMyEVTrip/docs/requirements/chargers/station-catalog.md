# Station catalog

Status: Implemented

Code: `FeedMyEVTrip/Models/AFDCStation.swift`, `FeedMyEVTrip/Services/AFDCChargerProvider.swift`, `Tests/AFDCCatalogChecks.swift`

Charger discovery uses a local U.S. public DC-fast catalog from AFDC. The bundled snapshot works without a network request. Refresh is separate and documented in [Charger data](charger-data.md).

## Requirements

### R1. Eligible station

A station is eligible only when all of these hold: country is US, fuel type is ELEC, access is public, status is E, DC-fast port count is greater than 0, and latitude and longitude are finite and inside -90...90 and -180...180.

### R2. Complete download

Decoding a catalog requires `total_results` greater than 0 and equal to the fuel-station array length. After eligibility and duplicate-ID removal, at least one station must remain. Otherwise the download is incomplete and must not replace a working snapshot.

### R3. Duplicate IDs

When two eligible records share an ID, the first is kept.

### R4. Connector labels

AFDC codes shown to the user are J1772COMBO as CCS, TESLA as NACS, CHADEMO as CHAdeMO, and J1772 as J1772 AC. Any other code is shown unchanged.

### R5. Summary

The station summary joins the network name, the DC-fast port count, and the connector labels with “ · ”, skipping empty parts.

### R6. Which snapshot loads

The app loads the newer of the bundled snapshot and a previously downloaded snapshot, compared by download date. An empty or wrong-version snapshot is ignored.

### R7. Stale catalog

The catalog is stale 30 days after its download date. A missing date is stale. Automatic refresh is attempted only when a search needs chargers, and at most once an hour while an older catalog is still available. A failed automatic refresh keeps the old stations and sets a warning.

## Test cases

| ID | Covers | Type | Given | When | Then |
| --- | --- | --- | --- | --- | --- |
| TC1 | R1 | Unit | A public available US DC-fast station with valid coordinates | Eligibility is evaluated | The station is eligible |
| TC2 | R1 | Unit | Copies of that station with status P, latitude 999, country CA, zero DC-fast ports, or a non-finite longitude | Eligibility is evaluated | Each copy is ineligible |
| TC3 | R2 | Unit | `total_results` does not equal the station array length | The payload is decoded | Decoding throws incomplete and returns no stations |
| TC4 | R2 | Unit | Every station is ineligible | The payload is decoded | Decoding throws incomplete |
| TC5 | R3 | Unit | Two eligible stations share an ID and a third is eligible with a new ID | The payload is decoded | Two stations remain and the first copy of the shared ID is kept |
| TC6 | R4 | Unit | Connector codes are J1772COMBO, TESLA, CHADEMO, J1772, and J3271 | Labels are requested | Labels are CCS, NACS, CHAdeMO, J1772 AC, and J3271 |
| TC7 | R5 | Unit | Network “ChargePoint”, 2 DC-fast ports, and CCS | The summary is built | The text is “ChargePoint · 2 DC-fast ports · CCS” |
| TC8 | R6 | Unit | The bundled snapshot is older than the downloaded snapshot, and both are version 1 and non-empty | The provider chooses a snapshot | The downloaded snapshot is used |
| TC9 | R6 | Unit | The downloaded file is empty or the wrong version | The provider chooses a snapshot | That file is ignored |
| TC10 | R7 | Unit | The download date is 30 days ago, and another is 29 days ago | Stale is evaluated | Only the 30-day snapshot is stale |
| TC11 | R7 | Unit | Stations are already loaded and the last automatic attempt was under an hour ago | A search loads chargers | No new download starts, and the existing stations are returned |

TC1–TC6 are partly covered by `Tests/AFDCCatalogChecks.swift`.
