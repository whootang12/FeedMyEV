# Connector preferences

Status: Implemented

Code: `FeedMyEVTrip/Models/ChargerConnector.swift`, `FeedMyEVTrip/Features/Settings/FoodPreferencesView.swift`

Preferences stores CCS, NACS, and CHAdeMO. Nearby and route searches use the same rule.

## Requirements

### R1. Choices and defaults

The choices are CCS (`J1772COMBO`), NACS (`TESLA`), and CHAdeMO (`CHADEMO`). Each defaults to on when no value is stored.

### R2. At least one choice

The Preferences screen does not allow the last selected connector to be turned off.

### R3. Match rule

A charger is allowed when at least one of its recognized connector codes is selected. Recognized codes are only CCS, NACS, and CHAdeMO. A charger with none of those codes is allowed.

### R4. Combined connectors

A station that lists more than one recognized connector is allowed when any selected connector is among them.

### R5. Where it applies

Nearby search filters after the region filter. Route search filters unsaved corridor candidates and saved candidates after a saved stop has been matched to the catalog. The filter applies on the next search, not to results already on screen.

## Test cases

| ID | Covers | Type | Given | When | Then |
| --- | --- | --- | --- | --- | --- |
| TC1 | R1 | Unit | No connector values are stored | Each choice is read | CCS, NACS, and CHAdeMO are on |
| TC2 | R1 | Unit | NACS is stored as off | Choices are read | NACS is off and the others stay on |
| TC3 | R2 | Integration | Only CCS is on | The user tries to turn CCS off | The CCS control stays on |
| TC4 | R3 | Unit | Only NACS is on | Codes are `TESLA` | The charger is allowed |
| TC5 | R3 | Unit | Only NACS is on | Codes are `J1772COMBO` | The charger is not allowed |
| TC6 | R3 | Unit | All three are off in storage | Codes are `J1772` only | The charger is allowed because it has no recognized DC connector |
| TC7 | R4 | Unit | CCS is off and CHAdeMO is on | Codes are `J1772COMBO` and `CHADEMO` | The charger is allowed |
| TC8 | R5 | Unit | NACS is off | A nearby region contains a Tesla-only station and a CCS station | Only the CCS station is returned |
| TC9 | R5 | Unit | CCS is off | A saved stop matches a CCS-only catalog station | That saved candidate is removed before driving checks |

TC4–TC7 are partly covered by `Tests/AFDCCatalogChecks.swift`.
