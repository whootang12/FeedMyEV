# Food preferences

Status: Implemented

Code: `FeedMyEVTrip/Models/FoodPreferenceKeys.swift`, `FeedMyEVTrip/Features/Settings/FoodPreferencesView.swift`, `FeedMyEVTrip/Features/Search/SearchView.swift`

Preferences stores how far the user will walk and which food categories to include.

## Requirements

### R1. Walking time

The maximum walk choices are 5, 10, 15, and 20 minutes. The default is 15. The value persists across launches.

### R2. Categories

Restaurants, cafés, and bakeries can each be on or off. All three default to on. The screen does not allow the last category to be turned off.

### R3. Search categories

A food search uses the categories that are on. If none are on, the search uses restaurants.

### R4. Estimate disclosure

The walking section says the times are straight-line estimates.

## Test cases

| ID | Covers | Type | Given | When | Then |
| --- | --- | --- | --- | --- | --- |
| TC1 | R1 | Unit | No walking value is stored | The preference is read | The maximum is 15 minutes |
| TC2 | R1 | Unit | The stored value is 10 | The preference is read | The maximum is 10 minutes |
| TC3 | R2 | Integration | Only restaurants are on | The user tries to turn restaurants off | Restaurants stay on |
| TC4 | R3 | Unit | Restaurants and bakeries are on and cafés are off | Search categories are built | The list is restaurant and bakery, without café |
| TC5 | R3 | Unit | All three stored values are off | Search categories are built | The list is restaurant only |
| TC6 | R1 | Integration | The user selects 20 minutes and leaves Preferences | Food is searched for a selected charger | The search radius uses 20 minutes |

## Later unit-test notes

TC4 and TC5 can target the category list in `SearchView` once that logic is a function. Radius conversion is specified in [Nearby food](nearby-food.md).
