# Place lookup and cache

Status: Partial

Code: `FeedMyEVTrip/Services/MapSearchService.swift`

MapKit resolves destination text and nearby food. Successful lookups are cached on device for seven days. Charger discovery does not use this cache. Whether the seven-day retention matches Apple’s terms is still an open review.

## Requirements

### R1. Destination resolution

A destination query is looked up as natural language. The first returned place is the resolved place. An empty result resolves to no place.

### R2. Destination cache

The cache key is `destination:` plus the query in lowercase. A fresh cached place is returned without a new MapKit request.

### R3. Food cache key

A food search key includes latitude and longitude to four decimal places, the radius rounded to whole meters, and the selected category identifiers sorted and comma-separated.

### R4. Cache lifetime and size

Entries older than seven days are dropped on load and on write. Charger-kind entries are dropped on load. At most 100 entries are kept, newest first.

### R5. Empty results are not cached

A lookup or food search that returns no places does not replace or create a cache entry.

### R6. Throttling

A throttled MapKit request is retried up to two more times, with delays of about 0.75 seconds, then 1.5 seconds, plus a small random amount. A third throttle fails as throttled. Cancellation is not retried.

### R7. Other failures

A URL error is reported as network unavailable. Any other MapKit failure is reported as service unavailable.

## Test cases

| ID | Covers | Type | Given | When | Then |
| --- | --- | --- | --- | --- | --- |
| TC1 | R2 | Unit | A cached destination exists for “Pennington” | “pennington” is resolved | The cached place is returned and no new request is required |
| TC2 | R3 | Unit | A search at 40.12344, -74.98765 with radius 1200.4 and categories bakery then restaurant | The cache key is built | The key uses 40.1234, -74.9877, radius 1200, and the categories in sorted order |
| TC3 | R4 | Unit | An entry created 7 days and 1 second ago, and a charger-kind entry | The cache loads | Both entries are absent |
| TC4 | R4 | Unit | 101 fresh entries | Another entry is stored | 100 entries remain and the oldest is gone |
| TC5 | R5 | Unit | A query returns no places | The result is stored | The cache has no entry for that key |
| TC6 | R6 | Unit | The first two attempts are throttled and the third succeeds | The search runs | The third response is returned |
| TC7 | R6 | Unit | Three attempts are throttled | The search runs | The error is throttled |
| TC8 | R6 | Unit | A search is cancelled during a throttle delay | Cancellation is requested | The error is cancellation, not throttle |
| TC9 | R7 | Unit | The request fails with a URL error, then with another MapKit error | Each error is mapped | The results are network unavailable, then service unavailable |

## Later unit-test notes

Cache key, expiry, and size can use an in-memory `UserDefaults` suite. Retry tests need a stub in place of `MKLocalSearch`.
