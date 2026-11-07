# Product brief

This document is the evolving product briefing and overview for Feed My EV Trip. Update it as the product direction becomes clearer; detailed, testable feature behavior belongs in [Feature requirements](requirements/README.md).

## Product idea

People are not simply searching for a charger. They are trying to choose a good place to stop during a journey—one that fits the route, the moment, their charging needs, and what they want to eat or do while the car charges.

The current experience asks people to choose between “Along a route” and “Near a place” before they can express that intent. A reimagined experience should begin with the journey and adapt to the kind of decision the person is trying to make.

## Product promise

Feed My EV Trip helps someone choose a useful charging stop on a drive by considering the whole stop: its position on the journey, the charging experience, the food nearby, and the cost of leaving and returning to the route.

The goal is not to produce the longest list of chargers. It is to make the stop decision easier.

## Who it is for

The first release is a personal road-trip tool for someone planning a drive or making a stop decision while traveling. On-road touch interaction assumes the person is parked or a passenger. A driver-safe or CarPlay experience is a separate future concern.

## Needs the product should serve

### Discover where to stop

Someone knows their destination but not the best stopping area. They may want to stop after a certain number of miles, after a period of driving, or around a moment such as dinner time.

### Choose a charger in a known area

Someone already knows the town, interchange, neighborhood, or general area where they want to stop. They need help comparing the chargers and amenities there.

### Start with food

Someone wants a type of food or a particular chain and wants to find route-compatible charging stops that match. Food should be able to shape discovery before a charger is selected.

### Revisit saved chargers during a trip

Someone saved chargers while planning and now wants to see where those options fall along the active route. Saved chargers should be presented in journey context rather than only as a separate historical list or map.

## Product principles

- Begin with the journey, not an implementation-oriented search mode.
- Ask for the minimum information needed to make useful progress.
- Treat the charger, food, walk, timing, and route impact as one stop decision.
- Let people express intent in familiar terms such as miles, driving time, meal time, place, cuisine, or restaurant chain.
- Make assumptions visible and editable.
- Explain why an area or stop is recommended.
- Use the map as context and validation, not necessarily as the first interaction.
- Prefer a few useful choices over a large undifferentiated result set.

## Current product foundations

The app already supports route-based and nearby charger searches, time- or distance-based stop windows, maximum detour limits, connector preferences, nearby food, walking-distance preferences, saved chargers, and a bundled catalog of public DC-fast stations.

Important gaps include journey-first search, destination autocomplete and disambiguation, time-of-day intent, cuisine or chain search, food-aware stop discovery, and comparing saved chargers against an active route.

## Product boundaries

The current scope uses a bundled AFDC charger catalog and MapKit for places, routes, food, maps, and navigation. Payments, accounts, live charger status, and battery-range prediction are outside the first release unless explicitly reconsidered.

## How this document evolves

Use this brief for product purpose, audience, principles, and major use cases. Put concrete search-page behavior in the [Search experience requirements](requirements/search/search-experience.md) and narrower feature behavior in the other requirement documents.

## Decision log

| Date | Decision | Reason |
| --- | --- | --- |
| 2026-09-27 | Treat search as a journey-first stop decision | People are choosing a useful break, not merely locating a charger |
| 2026-09-27 | Keep the product brief separate from feature requirements | Product direction should evolve without mixing narrative and testable behavior |
