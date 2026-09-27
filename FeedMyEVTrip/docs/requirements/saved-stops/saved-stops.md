# Saved stops

Status: Implemented

Code: `FeedMyEVTrip/Models/SavedStop.swift`, `FeedMyEVTrip/Features/Saved/SavedStopsView.swift`, `FeedMyEVTrip/Features/Saved/SavedStopDetailsView.swift`, `FeedMyEVTrip/Features/Search/SearchView.swift`

A saved stop is a charger the user keeps on this device, with the food names that were nearby at save time. The Saved tab also lists saved restaurants, specified in [saved restaurants](../food/saved-restaurants.md). Charger notes are specified in [notes and tags](notes-and-tags.md).

## Requirements

### R1. What is stored

Saving a charger stores its name, address, latitude, longitude, Apple place ID when present, AFDC station ID when present, the save date, and up to three nearby food names that MapKit provided. Those names are stored as one newline-separated string and read back by splitting on newlines.

### R2. One save

Saving an already saved charger does not create a second record. Two chargers match when they share an AFDC ID, otherwise an Apple place ID, otherwise they are within 20 meters.

### R3. List

The Saved tab lists stops newest first. The list can be deleted from. An empty list shows the empty state and does not show the list/map switch.

### R4. Map and details

The map shows each saved charger. Choosing one from the list or the map opens details with the name, address when present, save date, driving directions, an Apple Maps link, and the saved food names. Each food name opens [food details](../food/food-details.md) for that place. Driving directions open Apple Maps in driving mode toward the charger.

### R5. Food snapshot

Saved food names are the names captured at save time, along with each place’s coordinate, address, phone, and website when MapKit provided them. They are not refreshed when the catalog or nearby restaurants change. A save that has only a name looks up that place near the charger when it is opened.

### R6. Route inclusion

Saved chargers are candidates in [route search](../search/route-search.md). They still have to satisfy the stop window, detour limit, and connector preferences when connector codes are known.

## Test cases

| ID | Covers | Type | Given | When | Then |
| --- | --- | --- | --- | --- | --- |
| TC1 | R1 | Unit | Food names are “The Front Porch” and “Vito's Pizza” | A saved stop is created and its names are read | The stored text is those names separated by a newline, and the read list has both names in that order |
| TC2 | R1 | Unit | A charger with an AFDC ID and a place ID | It is saved | Both identifiers are stored with the coordinate and save date |
| TC3 | R2 | Unit | A saved stop and a charger share an AFDC ID but are 1 km apart | They are compared | They match |
| TC4 | R2 | Unit | Two chargers have no IDs and are 20 meters apart, then 21 meters apart | They are compared | 20 meters matches and 21 meters does not |
| TC5 | R2 | Integration | A charger is already saved | Save is tapped again | The store still has one record |
| TC6 | R3 | Unit | Stops were saved on March 1 and March 3 | The list is loaded | March 3 is first |
| TC7 | R3 | Integration | One stop exists | It is deleted | The empty state is shown |
| TC8 | R4 | Integration | A saved stop has an address and two food names | Details are opened | The name, address, date, food names, and both map actions are available, and each food name can open food details |
| TC9 | R5 | Unit | Food names were saved, then the live nearby list changes | The saved stop is read | The stored names are unchanged |
| TC10 | R6 | Unit | A saved charger is outside the route corridor but inside the time window and detour after driving checks | Route candidates are built | It is still checked, and it appears only if the driving checks pass |

## Later unit-test notes

TC1–TC4 and TC6 can use the model and sort. TC5–TC8 need SwiftData or the view. Route inclusion shares cases with route search TC9 and TC10.
