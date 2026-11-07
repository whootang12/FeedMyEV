# Codex

Preferences for AI assistants working in this repository. Read this before making changes. When a preference is stated while working, add it under **Log** in the same session.

## Documentation

- Keep project notes in `FeedMyEVTrip/docs/` so they appear in the Xcode project navigator.
- Feature requirements and their future unit-test cases live in `FeedMyEVTrip/docs/requirements/`, one feature per file.
- That folder is excluded from the app target. New notes belong there, and the exclusion in `project.pbxproj` must still cover them.
- The repository-root `README.md` is a link to `FeedMyEVTrip/docs/README.md`, so GitHub still shows the same file.

## Product

- The app finds a useful fast-charging stop on a drive, with nearby food that matches personal preferences.
- The first release is for personal road-trip testing.
- Charger discovery uses the bundled AFDC catalog. MapKit covers maps, places, routes, food, and navigation.
- Store the AFDC API key in the device Keychain. Never commit it.
- Leave payments, accounts, live charger status, and battery-range prediction alone unless they are explicitly requested. Current scope is in [MVP status](MVP_STATUS.md).

## Code

- The app is SwiftUI and SwiftData. New app code belongs in the existing `App`, `Features`, `Models`, `Services`, and `Resources` folders.
- Default actor isolation is MainActor.
- Catalog fixture checks stay in `Tests/` and run with `swiftc` from the repository root, as described in [AFDC charger catalog](AFDC_DATA.md).

## Collaboration

- Change only what the current request needs.
- Create a git commit or push only when asked.
- When a change affects what a person sees or does in the app, verify it and say what could not be checked.

## Log

- 2026-11-07: The target stop window defaults to hours and steps by 0.5 hours. Miles remain available. Preference rows in the search drawer edit their setting in place; rows for filters that don't exist yet are plain text.

- 2026-10-03: Style View details like the Apple Maps Website action: a rounded, lightly tinted button with a blue icon above its label.

- 2026-10-03: Closing charger details returns to the previous position in the results list and restores the results drawer height, as well as the map region.

- 2026-10-03: Charger selection uses a prominent View details button to zoom to the stop and show every matching nearby food option. Keep the top-left Results back button on initial charger selection. After View details, replace it with a top-right X that returns to the results list and restores the previous map region. Remove the Charging stop expand control and Back to area button.

- 2026-09-26: Started this file. Moved `AFDC_DATA.md` and `MVP_STATUS.md` into `docs/` so project notes live with the committed repository and stay out of the app bundle.
- 2026-09-26: Keep project notes in `FeedMyEVTrip/docs/` so they are visible in Xcode, and keep that folder out of the app target.
- 2026-09-26: Walking directions from a restaurant start at the selected charger and end at the restaurant.
- 2026-09-26: Charger connector preferences are CCS, NACS, and CHAdeMO. A stop stays in results when it has at least one selected connector.
- 2026-09-26: Detailed feature requirements and test cases live in `FeedMyEVTrip/docs/requirements/`, one feature per file.
- 2026-09-27: Keep the evolving product briefing in `docs/PRODUCT_BRIEF.md`; keep concrete search-page behavior in `docs/requirements/search/search-experience.md` and related feature requirement files.
