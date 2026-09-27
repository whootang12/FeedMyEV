# Food-aware recommendations

Status: Planned

Code: route results in `FeedMyEVTrip/Services/RouteStopService.swift` are accepted before any food search.

Today, food loads only after a charger is selected. A recommended stop can have no matching food inside the walking limit.

## Requirements

### R1. Food before recommendation

A route stop is recommended only after food within the walking limit has been checked for that charger.

### R2. Matching food required

A stop with no food place inside the walking limit and selected categories is not recommended. The search says when stops were removed for that reason.

### R3. Detour order remains

Among stops that have matching food, order is still increasing detour, as in [route search](../search/route-search.md).

### R4. Failure

If the food check fails for a candidate, that candidate is not shown as a confirmed recommendation, and the result notice says the food check was incomplete.

## Test cases

| ID | Covers | Type | Given | When | Then |
| --- | --- | --- | --- | --- | --- |
| TC1 | R2 | Unit | Two chargers pass the detour limit and only one has food inside the walking limit | Recommendations are built | Only the charger with food is returned |
| TC2 | R2 | Unit | Every detour-qualified charger has no food in range | Recommendations are built | The list is empty and the notice says food removed the stops |
| TC3 | R3 | Unit | Two chargers both have food, with detours of 20 and 8 minutes | Recommendations are built | The 8-minute detour is first |
| TC4 | R4 | Unit | The food check fails for one candidate and succeeds with a match for another | Recommendations are built | Only the successful match is recommended, and the notice says the food check was incomplete |

Do not add these as passing tests until the feature exists.
