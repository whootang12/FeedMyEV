# Notes and tags

Status: Partial

Code: `FeedMyEVTrip/Models/SavedStop.swift`, `FeedMyEVTrip/Features/Saved/SavedStopDetailsView.swift`, `FeedMyEVTrip/Features/Search/StopResultPanel.swift`

Each saved charger has one editable note. Tags are not stored, and the saved list cannot be filtered by them.

## Requirements

### R1. Note

Each saved stop has an editable note. An empty note is allowed. The note persists with the stop and can be cleared. The same notes box is on saved-stop details and on the charging-stop panel. Typing a note for a charger that is not saved yet saves that charger once nearby food has finished loading, so the food-name snapshot can be stored with it.

### R2. Tags

Each saved stop has zero or more tags. Adding a tag twice does not duplicate it. A tag can be removed without deleting the stop. Tags are still planned.

### R3. Display

Details and the charging-stop panel show the note. The saved list shows tags when any exist. Tag display is still planned.

### R4. Unchanged identity

Editing a note or tags does not change the save date, location, or food-name snapshot.

## Test cases

| ID | Covers | Type | Given | When | Then |
| --- | --- | --- | --- | --- | --- |
| TC1 | R1 | Unit | A saved stop has no note | The note “Pull-through stalls” is saved, then cleared | The note is stored, then empty |
| TC2 | R2 | Unit | A stop has no tags | The tag “favorite” is added twice, then removed | The tag appears once, then the tag list is empty |
| TC3 | R3 | Integration | A stop has a note and one tag | Details and the saved list are shown | Both show the tag, and details show the note |
| TC4 | R4 | Unit | A stop was saved on a known date with two food names | The note changes | The save date, coordinate, and food names stay the same |

Note behavior can be tested from the cases above. Do not add tag cases as passing tests until tags exist.
