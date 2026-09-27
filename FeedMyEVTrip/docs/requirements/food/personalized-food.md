# Personalized food

Status: Partial

Code: chains and their effect on nearby food are in [saved restaurants](saved-restaurants.md). Food preferences in `FeedMyEVTrip/Features/Settings/FoodPreferencesView.swift` still cover categories and walking time only.

Saved chains are stored and nearby food prefers them. Cuisines are not saved, and there is no separate search for a chain yet.

## Requirements

### R1. Saved tastes

The user can save restaurant chains, as specified in [saved restaurants](saved-restaurants.md), and cuisines. The list persists across launches and can be edited or cleared. Cuisine saving is still planned.

### R2. Search use

Food results prefer places that match a saved chain or cuisine. A place that matches neither still appears after the matches when the category and walking limit allow it. Chain preference is implemented. Cuisine preference is still planned.

### R3. No tastes saved

When no chains or cuisines are saved, food order stays the distance order from [nearby food](nearby-food.md).

## Test cases

| ID | Covers | Type | Given | When | Then |
| --- | --- | --- | --- | --- | --- |
| TC1 | R1 | Unit | The user adds “Taqueria” and removes it | Preferences are read after each change | The cuisine is stored, then absent |
| TC2 | R2 | Unit | “Wawa” is a preferred chain and two places are equally close, one named Wawa | Results are ordered | Wawa comes first |
| TC3 | R2 | Unit | A preferred cuisine matches one place beyond the walking limit | Results are filtered | That place is excluded |
| TC4 | R3 | Unit | No chains or cuisines are saved | Results are ordered | Order is increasing distance only |

Chain ordering is covered by [saved restaurants](saved-restaurants.md) TC9 and TC10. Do not add cuisine cases as passing tests until that part exists.
