# Walking routes

Status: Planned

Code: walking time in `FeedMyEVTrip/Features/Search/SearchView.swift` uses straight-line distance.

The current estimate is meters divided by 80, and the food filter uses that same straight-line radius. Opening Maps for walking directions is already specified in [food details](food-details.md).

## Requirements

### R1. Pedestrian route

The walking time and distance shown for a restaurant come from a pedestrian route from the charger to the restaurant.

### R2. Limit uses the route

A restaurant is kept only when the pedestrian route time is within the maximum walking minutes. A short straight-line distance with a longer walk is removed.

### R3. Failed route

When a pedestrian route cannot be calculated, that restaurant is omitted and the food result says the walking check was incomplete.

### R4. Straight-line fallback is labeled

Until this feature exists, any walking time derived from straight-line distance stays labeled as an estimate.

## Test cases

| ID | Covers | Type | Given | When | Then |
| --- | --- | --- | --- | --- | --- |
| TC1 | R1 | Integration | A charger and restaurant have a known pedestrian route of 6 minutes | Food details are shown | The displayed walk is 6 minutes from that route |
| TC2 | R2 | Unit | The maximum walk is 10 minutes, the straight-line time is 4 minutes, and the pedestrian route is 12 minutes | The place is filtered | The place is removed |
| TC3 | R2 | Unit | The pedestrian route is 10 minutes and the maximum is 10 | The place is filtered | The place is kept |
| TC4 | R3 | Unit | The pedestrian route fails | Food results are built | The place is absent and the incomplete-check notice is set |
| TC5 | R4 | Unit | Route-based walking is not available | The current estimate is shown | The text includes an estimate marker |

Do not add TC1–TC4 as passing tests until the feature exists. TC5 describes the current estimate in [nearby food](nearby-food.md).
