# Search experience

Status: Partial

Related requirements: [Route search](route-search.md), [Nearby search](nearby-search.md), [Place lookup and cache](place-lookup.md), [Type-ahead search](type-ahead.md), [Food-aware recommendations](../food/food-aware-recommendations.md), and [Saved stops](../saved-stops/saved-stops.md)

The search page begins with the journey and adapts to the kind of stop decision the person wants to make. It replaces the need to choose “Along a route” or “Near a place” before expressing intent.

## Requirements

### R1. Journey entry

The search page first establishes the destination. It uses the current location as the default origin when available and lets the person enter a different starting place.

### R2. Destination suggestions

While the person types a destination, the page shows matching address and place suggestions. Each suggestion includes enough geographic context to distinguish similarly named results. Selecting a suggestion stores the resolved place for the search rather than resolving the displayed text again.

### R3. Explicit destination

The page makes the selected destination visible and editable. It must not silently select the first result when entered text is ambiguous. Loading, no-match, lookup-failure, and retry states are presented in the destination entry area.

### R4. Stop intent

After establishing the journey, the person can express one or more of these intents without switching between top-level search modes:

- Discover a stopping area by driving time, route distance, or approximate time of day.
- Focus on a named town, interchange, neighborhood, address, or other general area.
- Prefer one or more food types or a particular restaurant chain.
- Consider chargers saved during earlier trip planning.

### R5. Progressive detail

The page asks only for information needed by the expressed intent. Detour, timing, distance, food, walking, and charger constraints remain available for review and adjustment without requiring every value before the first search.

### R6. Time-of-day intent

A phrase or choice such as “around dinner” becomes an estimated arrival window using the trip start and route timing. The inferred window is shown to the person and can be edited before or after searching.

### R7. Candidate areas

When the person has not named an area, search may group viable stops into candidate areas along the route. Each area shows its expected arrival point and enough information to explain why it is relevant before the person compares individual stops.

### R8. Area-focused search

When the person names a general stopping area, results prioritize viable chargers in that area while retaining route arrival and detour context. A materially better nearby option outside the interpreted area may be shown only when it is clearly identified as an alternative.

### R9. Food-shaped discovery

A cuisine, food type, or chain can influence which stops are discovered and ranked before a charger is selected. Exact matches are preferred. If they are scarce or unavailable, broadened alternatives are identified as such rather than presented as exact matches.

### R10. Saved chargers in context

Saved chargers that are relevant to the active route appear with current arrival and detour context. Saved status is visible, but saving a charger does not by itself make an unsuitable stop rank above better route-compatible options.

### R11. Whole-stop results

Results represent complete stops rather than charger locations alone. A result may include route arrival, detour, charger suitability, matching food, walking effort, and saved status. The page explains the most important reasons for its ordering without claiming knowledge the available data does not provide.

### R12. Search refinement

The person can adjust the destination, stop intent, or constraints and run the search again without rebuilding the entire journey. Existing inputs remain visible or summarized while results are shown.

### R13. Map and list coordination

The map and result list represent the same candidate areas and stops. Selecting an item in either representation identifies the same result and provides a path to stop details.

### R14. Trip-time presentation

Planning and on-road decisions use the same journey and search model. When a trip is underway, the page favors a concise, glanceable presentation suitable for a passenger or parked driver; it does not represent itself as safe for active touch use while driving.

### R15. Partial data

The page distinguishes unavailable data from negative data. It must not imply that charger availability, reliability, or another unsupported attribute has been checked when the app does not have that information.

### R16. Nearby results

Search here and Nearby Chargers open the nearby chargers list. That list is not the route results list and does not show the route stop window. With no search and no selected place, panning the map shows Search here. The button does not wait for the location control.

### R17. Drawer close

A drawer that can be closed shows one X as its trailing control. That header does not also show the expand and collapse caret. The drawer does not show “Edit journey,” “Back to results,” or the old “Search nearby” form.

### R18. Close directions

After a place is selected, opening directions and then closing them returns to that place. Closing does not clear the searched place.

### R19. One drawer

The search field and the content under it are one drawer. Resizing or scrolling the drawer moves that field with the content. The content does not scroll in its own area beneath a fixed search field.

## Test cases

| ID | Covers | Type | Given | When | Then |
| --- | --- | --- | --- | --- | --- |
| TC1 | R1 | Integration | Current location is available | The search page opens | Current location is the default origin and destination entry is ready |
| TC2 | R2 | Integration | The person enters part of an address | Matching suggestions arrive | Suggestions show distinguishing place and address context |
| TC3 | R2, R3 | Integration | Two suggestions have similar names | The person selects one | That resolved place is used by the next search |
| TC4 | R3 | Integration | A destination query fails | The lookup completes | The page shows a retryable error without choosing a destination |
| TC5 | R4, R5 | Unit | The person chooses a distance-based stop intent | Search inputs are presented | Distance is requested and unrelated advanced inputs are not required |
| TC6 | R6 | Unit | Trip timing puts dinner approximately 150 minutes into the route | “Around dinner” is selected | An editable arrival window around that point is shown |
| TC7 | R7 | Integration | Viable chargers form multiple clusters along the route | Broad discovery completes | Candidate areas show route arrival context before individual stop comparison |
| TC8 | R8 | Integration | A named area and a better option just outside it are available | Results are shown | In-area stops are prioritized and the outside option is labeled as an alternative |
| TC9 | R9 | Integration | A requested chain has exact matches and other restaurants along the route | Search completes | Exact chain matches rank first and other restaurants are identified as alternatives |
| TC10 | R10 | Integration | Saved chargers fall on and far away from the active route | Search completes | Relevant saved chargers show route context and the irrelevant charger is not promoted |
| TC11 | R11, R15 | Unit | A stop lacks live availability data | Its result is built | Availability is shown as unknown or omitted, not unavailable |
| TC12 | R12 | Integration | Results are visible | The person changes the desired stop time | The journey is retained and refreshed results use the new time |
| TC13 | R13 | UI | A stop appears on the map and in the list | Either representation is selected | Both identify the same stop and expose its details |
| TC14 | R14 | UI | The trip is underway | The search page is shown | The presentation is concise and does not claim active-driver suitability |
| TC15 | R16 | Integration | A place is selected and the map has moved | Search here is tapped | The nearby chargers list opens, without the route stop window |
| TC20 | R16 | UI | No search has been made and no place is selected | The map is panned | Search here appears without using the location control |
| TC16 | R16 | Integration | A place is selected | Nearby Chargers is tapped | The nearby chargers list opens for that place, without the route results page |
| TC17 | R17 | UI | Directions are open on the route drawer | The drawer header is shown | The header has a trailing X and does not have an expand or collapse caret |
| TC21 | R17 | UI | Nearby chargers are open | The drawer header is shown | The header has a trailing X and does not have an expand or collapse caret |
| TC22 | R17 | UI | A place is selected | The drawer header is shown | The header has a trailing X and does not have an expand or collapse caret |
| TC23 | R17 | UI | Any search drawer is open | The drawer is shown | It does not show “Edit journey,” “Back to results,” or the old “Search nearby” form |
| TC18 | R18 | Integration | A place was searched and directions were opened | X is tapped | The selected place is shown again and the search is not cleared |
| TC19 | R19 | UI | The search field and the preferences under it are visible | The drawer is resized or its content is scrolled | The search field and the content move together |

TC15–TC23 describe the current drawer. Do not add any of these cases as passing tests until the corresponding behavior exists and a unit-test target is in place.
