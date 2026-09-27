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

- 2026-09-26: Started this file. Moved `AFDC_DATA.md` and `MVP_STATUS.md` into `docs/` so project notes live with the committed repository and stay out of the app bundle.
- 2026-09-26: Keep project notes in `FeedMyEVTrip/docs/` so they are visible in Xcode, and keep that folder out of the app target.
- 2026-09-26: Walking directions from a restaurant start at the selected charger and end at the restaurant.
- 2026-09-26: Charger connector preferences are CCS, NACS, and CHAdeMO. A stop stays in results when it has at least one selected connector.
- 2026-09-26: Detailed feature requirements and test cases live in `FeedMyEVTrip/docs/requirements/`, one feature per file.
