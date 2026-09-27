# Feature requirements

Each feature has its own file. Folders group related features. These notes are the source for future unit tests.

## How to read a file

- **Status** is Implemented, Partial, or Planned.
- **R** IDs are requirements. They stay stable when wording is edited.
- **TC** IDs are test cases. A future unit test should include the ID in its name, for example `test_TC3_rejectsIncompleteCatalog`.
- **Type** says where the case belongs: Unit, or Integration when it needs MapKit, the Keychain, or a device.
- Planned requirements describe intended behavior. Their test cases should not be written as passing tests until the behavior exists.

## Features

### Search

- [Nearby search](search/nearby-search.md)
- [Route search](search/route-search.md)
- [Place lookup and cache](search/place-lookup.md)
- [Type-ahead search](search/type-ahead.md) — planned

### Chargers

- [Station catalog](chargers/station-catalog.md)
- [Connector preferences](chargers/connector-preferences.md)
- [Charger data](chargers/charger-data.md)
- [Charging power](chargers/charging-power.md) — planned

### Food

- [Food preferences](food/food-preferences.md)
- [Nearby food](food/nearby-food.md)
- [Food details](food/food-details.md)
- [Saved restaurants](food/saved-restaurants.md) — partial
- [Personalized food](food/personalized-food.md) — partial
- [Food-aware recommendations](food/food-aware-recommendations.md) — planned
- [Walking routes](food/walking-routes.md) — planned

### Saved stops

- [Saved stops](saved-stops/saved-stops.md)
- [Notes and tags](saved-stops/notes-and-tags.md) — partial
