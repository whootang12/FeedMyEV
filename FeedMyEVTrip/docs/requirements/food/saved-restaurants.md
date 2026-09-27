# Saved restaurants

Status: Partial

Code: `FeedMyEVTrip/Models/SavedRestaurantChain.swift`, `FeedMyEVTrip/Models/SavedRestaurantLocation.swift`, `FeedMyEVTrip/Features/Search/FoodDetailsView.swift`, `FeedMyEVTrip/Features/Search/NearbyFoodOrdering.swift`, `FeedMyEVTrip/Features/Saved/SavedStopsView.swift`, `FeedMyEVTrip/Features/Saved/SavedRestaurantLocationDetailsView.swift`

Food details can save a restaurant chain and a specific location. A location has one note. The Saved tab lists both. Nearby food puts saved chains first. Cuisines and an explicit chain search are still planned.

## Requirements

### R1. Save a chain

Food details can save the restaurant’s place name as a chain, and can remove that chain. The saved name is shown on the button. Saving the same name again, ignoring case and surrounding spaces, does not create a second record. A place with no name cannot be saved as a chain. Removing a chain does not remove saved locations.

### R2. Chain identity

MapKit does not provide a brand id. A place matches a saved chain when its name equals the saved name after trimming spaces and ignoring case. Opening any matching place shows the chain as saved.

### R3. Save a location

Food details can save and remove the specific place. A saved location stores its name, address, latitude, longitude, Apple place id when present, save date, and one note. Two locations match when they share a place id, otherwise when they are within 20 meters. Chain and location saves are independent.

### R4. Location note

Each saved location has one editable note. An empty note is allowed. Clearing the note keeps the location. Removing the location removes its note. Typing a note for a place that is not saved yet saves that location.

### R5. Saved list

The Saved tab has Chargers and Food. Food lists chains and locations, newest first. A location row opens details with its note. Chains and locations can be deleted from the list. An empty charger list does not hide saved food, and an empty food list does not hide saved chargers.

### R6. Nearby order

After the walking-radius filter in [nearby food](nearby-food.md), places that match a saved chain come first. Distance order stays inside that group, and places that do not match still follow. With no saved chains, order stays distance-only.

### R7. Later search

The stored chain name can be used later to search for that chain. This release does not add that search. Cuisine preferences remain in [personalized food](personalized-food.md).

## Test cases

| ID | Covers | Type | Given | When | Then |
| --- | --- | --- | --- | --- | --- |
| TC1 | R1 | Unit | No chain is saved | “Wawa” is saved twice, then removed | One chain named Wawa is stored, then none |
| TC2 | R1 | Unit | “Wawa” is saved | “ wawa ” is saved | The store still has one chain |
| TC3 | R2 | Unit | “Wawa” is saved | A place named “wawa” and a place named “Wawa #12” are compared | Only “wawa” matches |
| TC4 | R3 | Unit | A location has place id A | Another place has place id A, 1 km away | They match |
| TC5 | R3 | Unit | Two places have no place id and are 20 meters apart, then 21 meters apart | They are compared | 20 meters matches and 21 meters does not |
| TC6 | R4 | Unit | A location has no note | The note “Sit outside” is saved, then cleared | The note is stored, then empty, and the location remains |
| TC7 | R4 | Unit | A location has a note | The location is removed | The location and its note are gone |
| TC8 | R5 | Unit | A chain was saved on March 1 and a location on March 3 | The food list is loaded | March 3’s location is first, and the chain is listed separately |
| TC9 | R6 | Unit | “Wawa” is a saved chain and two places are equally close, one named Wawa | Results are ordered | Wawa comes first, and the other place still appears |
| TC10 | R6 | Unit | No chains are saved | Places are 400, 100, and 250 meters away | The order is 100, 250, 400 |
| TC11 | R7 | Unit | “Wawa” is saved | The app looks for a chain-search field | There is no chain-search field |

Do not add these as passing tests until a unit-test target exists. TC11 is a product boundary, not a search feature.
