# Charging power

Status: Planned

Code: station records in `FeedMyEVTrip/Models/AFDCStation.swift` do not store kilowatts today.

Connector preferences do not prove that a stall can charge the user’s vehicle at 150 kW or more. AFDC’s station-level connector list can include slower ports at the same site.

## Requirements

### R1. Power preference

Preferences includes a minimum DC-fast power, with 150 kW as the road-trip default.

### R2. Station qualification

A station qualifies when at least one port has a selected connector and a reported power at or above the minimum.

### R3. Missing power

A port with no reported power does not satisfy the minimum. The result explains that power was not reported rather than treating it as a match.

### R4. Search use

Nearby and route searches apply this rule together with connector preferences.

## Test cases

| ID | Covers | Type | Given | When | Then |
| --- | --- | --- | --- | --- | --- |
| TC1 | R1 | Unit | No power preference is stored | The preference is read | The minimum is 150 kW |
| TC2 | R2 | Unit | The minimum is 150 kW and a CCS port is reported at 150 kW | The station is evaluated | It qualifies |
| TC3 | R2 | Unit | The only CCS port is reported at 50 kW and NACS is off | The station is evaluated | It does not qualify |
| TC4 | R3 | Unit | The only selected connector has a null power | The station is evaluated | It does not qualify, and the reason is missing power |
| TC5 | R4 | Unit | One nearby station is 50 kW and another is 250 kW for the selected connector | Nearby search finishes | Only the 250 kW station remains |

Do not add these as passing tests until the feature exists.
