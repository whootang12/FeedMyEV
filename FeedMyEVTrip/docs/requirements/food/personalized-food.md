# Personalized food

Status: Planned

Code: food preferences in `FeedMyEVTrip/Features/Settings/FoodPreferencesView.swift` currently cover categories and walking time only.

The user cannot yet save preferred chains or cuisines, and food search does not rank or filter by them.

## Requirements

### R1. Saved tastes

The user can save restaurant chains and cuisines. The list persists across launches and can be edited or cleared.

### R2. Search use

Food results prefer places that match a saved chain or cuisine. A place that matches neither still appears after the matches when the category and walking limit allow it.

### R3. No tastes saved

When no chains or cuisines are saved, food order stays the distance order from [nearby food](nearby-food.md).

## Test cases

| ID | Covers | Type | Given | When | Then |
| --- | --- | --- | --- | --- | --- |
| TC1 | R1 | Unit | The user adds “Taqueria” and removes it | Preferences are read after each change | The cuisine is stored, then absent |
| TC2 | R2 | Unit | “Wawa” is a preferred chain and two places are equally close, one named Wawa | Results are ordered | Wawa comes first |
| TC3 | R2 | Unit | A preferred cuisine matches one place beyond the walking limit | Results are filtered | That place is excluded |
| TC4 | R3 | Unit | No chains or cuisines are saved | Results are ordered | Order is increasing distance only |

Do not add these as passing tests until the feature exists.
