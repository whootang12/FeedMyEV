# Type-ahead search

Status: Planned

Code: origin and destination fields in `FeedMyEVTrip/Features/Search/FindMyStopView.swift`

Typing a starting place or destination currently submits the full text to MapKit only when the search runs. There is no suggestion list.

## Requirements

### R1. Suggestions while typing

After the user pauses typing in a place field, the app shows place suggestions for the current text.

### R2. Choosing a suggestion

Choosing a suggestion fills that field with the selected place and uses that place for the next search.

### R3. Short input

Fewer than two characters does not request suggestions.

### R4. Stale responses

A slower response for an older query does not replace suggestions for the current query.

## Test cases

| ID | Covers | Type | Given | When | Then |
| --- | --- | --- | --- | --- | --- |
| TC1 | R3 | Unit | The field contains one character | The suggestion delay elapses | No lookup is requested |
| TC2 | R1 | Integration | The field contains “Penning” | The suggestion delay elapses | Suggestions for that text are shown |
| TC3 | R2 | Integration | A suggestion is visible | The user chooses it | The field shows that place, and search uses it |
| TC4 | R4 | Unit | A request for “Pen” is still running when the query becomes “Pennington” | The “Pen” response arrives last | The visible suggestions belong to “Pennington” |

Do not add these as passing tests until the feature exists.
