# Nearby food

Status: Partial

Code: `FeedMyEVTrip/Features/Search/SearchView.swift`, `FeedMyEVTrip/Services/MapSearchService.swift`

Food is loaded after the user selects a charger. It is not used to rank route stops. Walking time is a straight-line estimate. Real walking routes are specified separately in [Walking routes](walking-routes.md).

## Requirements

### R1. When food loads

Selecting a charger starts a food search and clears the previous food list. Leaving that charger ignores a late response from the earlier search.

### R2. Radius

The search radius in meters is the maximum walking minutes times 80. A returned place farther than that straight-line distance from the charger is removed.

### R3. Categories

The search uses the categories from [food preferences](food-preferences.md).

### R4. Order

Remaining places are ordered by increasing straight-line distance from the charger. When a saved chain matches, [saved restaurants](saved-restaurants.md) moves those places ahead of the others and keeps distance order inside each group.

### R5. Walking estimate

The estimate shows feet as meters times 3.28084, rounded to the nearest foot, and minutes as the ceiling of meters divided by 80, with a minimum of 1. The text form is “{feet} ft · ~{minutes} min walk”.

### R6. Empty food

When the search succeeds and nothing remains inside the radius, the panel says no nearby food was found within the walking range.

### R7. Failure

A food-search failure clears the food list and shows the search error. Cancellation does not show an error.

## Test cases

| ID | Covers | Type | Given | When | Then |
| --- | --- | --- | --- | --- | --- |
| TC1 | R2 | Unit | The maximum walk is 15 minutes | The radius is calculated | The radius is 1,200 meters |
| TC2 | R2 | Unit | The radius is 1,200 meters and places are at 1,200 and 1,201 meters | Results are filtered | Only the place at 1,200 meters remains |
| TC3 | R4 | Unit | Places are 400, 100, and 250 meters from the charger | Results are sorted | The order is 100, 250, 400 |
| TC4 | R5 | Unit | The distance is 80 meters | The estimate is formatted | The text is “262 ft · ~1 min walk” |
| TC5 | R5 | Unit | The distance is 81 meters | The estimate is formatted | The minutes value is 2 |
| TC6 | R5 | Unit | The distance is 1 meter | The estimate is formatted | The minutes value is 1 |
| TC7 | R1 | Integration | Food for charger A is still loading | The user selects charger B | Charger A’s response does not fill charger B’s list |
| TC8 | R6 | Integration | The food search returns no places inside the radius | Selection finishes | The empty walking-range message is shown |
| TC9 | R7 | Integration | The food search is cancelled | Selection is still current | The panel does not show a cancellation error |

## Later unit-test notes

TC1–TC6 should move to pure functions before they are written as tests. TC7–TC9 need the search flow.
