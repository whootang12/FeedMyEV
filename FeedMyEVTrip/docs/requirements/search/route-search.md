# Route search

Status: Implemented

Code: `FeedMyEVTrip/Services/RouteStopService.swift`, `FeedMyEVTrip/Features/Search/FindMyStopView.swift`

**Along a route** finds public DC-fast chargers in a stop window, checks driving time, and orders the stops that stay within the detour limit.

## Requirements

### R1. Stop window

A stop window has a unit of minutes or miles and an inclusive lower and upper bound. `StopWindow.contains` uses minutes when the unit is minutes, and miles when the unit is miles.

### R2. Window before the destination

If the direct driving time or distance to the destination is not greater than the window’s lower bound, the search fails with a message that the destination is before the stop window.

### R3. Starting place

An empty origin uses the current location. A missing current location fails and asks for a starting place. An origin or destination that cannot be resolved fails with a message naming which place failed.

### R4. Route geometry

Distance is measured along the route polyline. A requested distance is clamped to the polyline. Positions between vertices are linearly interpolated in map points. A coordinate’s projection is the closest point on any segment, reported as distance along the route and perpendicular offset. A polyline with fewer than two points has length 0 and a projection offset of infinity.

### R5. Corridor

Unsaved candidates must fall inside the route’s bounding rectangle expanded by 8 km, within 8 km of the polyline, and inside the stop window expanded by 12% for minutes or 2% for miles. They are ordered by perpendicular offset. At most 12 unsaved candidates receive a driving-time check.

### R6. Saved candidates

Saved chargers skip the corridor filter and the 12-candidate cap. Each is replaced by the matching catalog station when one exists, then kept only when [connector preferences](../chargers/connector-preferences.md) allow it. Matching uses AFDC station ID, then Apple place ID, then a distance of 20 meters or less.

### R7. Detour

Detour minutes are the driving time from the origin to the charger plus the charger to the destination, minus the direct trip, divided by 60, and never below 0. A stop is kept only when that value is at most the maximum detour. Detours do not include charging or meal time.

### R8. Order and notice

Accepted stops are ordered by increasing detour. A partial failure of some driving requests adds a notice that results may be incomplete. A throttled driving request fails the search. When more than 12 unsaved candidates exist, the notice says only 12 plus saved stops were checked.

### R9. Map display

The route shows a start marker, a destination marker, and a highlighted segment for the requested window. The highlighted segment is an approximation. Acceptance uses the calculated driving estimates.

## Test cases

| ID | Covers | Type | Given | When | Then |
| --- | --- | --- | --- | --- | --- |
| TC1 | R1 | Unit | A window of 60–120 minutes | Arrival is 60, 120, and 121 minutes | 60 and 120 are inside; 121 is outside |
| TC2 | R1 | Unit | A window of 30–50 miles | Arrival is 40 miles and 90 minutes | The miles value decides, so 40 miles is inside |
| TC3 | R2 | Unit | Direct travel is 40 minutes and the window starts at 60 | The route is validated | The search fails because the destination is before the window |
| TC4 | R4 | Unit | A two-point polyline | A distance before the start, at the midpoint, and past the end is requested | Results are the start, the interpolated midpoint, and the end |
| TC5 | R4 | Unit | A polyline with one point | Its length and a projection are requested | Length is 0 and the projection offset is infinite |
| TC6 | R4 | Unit | A straight segment with a repeated vertex | A nearby coordinate is projected | Along-route distance and offset match the closest segment, and the zero-length vertex does not break the fraction |
| TC7 | R5 | Unit | Candidates at 7.9 km and 8.1 km from the polyline, inside the window | The corridor filter runs | Only the 7.9 km candidate remains, and it is ordered before farther candidates |
| TC8 | R5 | Unit | 13 unsaved candidates pass the corridor | Driving checks are selected | Only the 12 with the smallest offset are checked |
| TC9 | R6 | Unit | A saved stop matches a catalog station by AFDC ID, and that station is NACS-only while NACS is off | Candidates are prepared | The saved stop is excluded |
| TC10 | R6 | Unit | A saved stop has no catalog match and no connector codes | Candidates are prepared | The saved stop remains and is not subject to the 12-candidate cap |
| TC11 | R6 | Unit | Two chargers have different IDs and coordinates 19 meters apart, then 21 meters apart | `ChargerResult.matches` is evaluated | 19 meters matches; 21 meters does not, unless an AFDC or place ID matches |
| TC12 | R7 | Unit | Direct travel is 100 minutes, origin-to-charger is 70, and charger-to-destination is 50 | Detour is calculated | Detour is 20 minutes |
| TC13 | R7 | Unit | The two legs sum to less than the direct trip | Detour is calculated | Detour is 0 |
| TC14 | R7 | Unit | Maximum detour is 15 minutes | A stop’s detour is 15 and another is 16 | Only the 15-minute stop is kept |
| TC15 | R8 | Unit | Accepted detours are 12, 4, and 9 minutes | Results are returned | Order is 4, 9, 12 |
| TC16 | R8 | Integration | One driving request is throttled | Route search runs | The search fails with the throttled error and does not return a partial list as success |
| TC17 | R9 | Integration | A route search succeeds | The map is shown | Start, destination, and the window highlight are visible, and listed stops match the calculated window |

## Later unit-test notes

`StopWindow`, `RouteGeometry`, detour math, candidate capping, and `ChargerResult.matches` can be tested without a live route. TC16 and TC17 need MapKit.
