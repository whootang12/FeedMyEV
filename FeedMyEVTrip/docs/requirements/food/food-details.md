# Food details

Status: Implemented

Code: `FeedMyEVTrip/Features/Search/FoodDetailsView.swift`

The food sheet shows the walking estimate, address, phone, and website when MapKit provides them, plus links to other apps.

## Requirements

### R1. Identity

The title is the place name, or “Food details” when the name is missing. The sheet shows the walking estimate from [nearby food](nearby-food.md) and a single-line address. A missing address shows “Address unavailable.”

### R2. Contact links

A phone number is shown only when one exists. The telephone link keeps digits and plus signs from that number. A website is shown only when one exists.

### R3. Apple Maps walking route

Open in Apple Maps requests walking directions whose first stop is the selected charger and whose destination is the restaurant.

### R4. Google Maps walking route

Open in Google Maps opens a directions URL with the charger coordinate as the origin, the restaurant coordinate as the destination, and travel mode walking.

### R5. Yelp

Search on Yelp opens a Yelp search for the restaurant name at the restaurant coordinate. It does not request directions.

## Test cases

| ID | Covers | Type | Given | When | Then |
| --- | --- | --- | --- | --- | --- |
| TC1 | R1 | Unit | The place name is missing and no address is available | The sheet content is built | The title is “Food details” and the address is “Address unavailable” |
| TC2 | R2 | Unit | The phone number is “(609) 555-0142” | The telephone URL is built | The URL is `tel:6095550142` |
| TC3 | R2 | Unit | The phone number is “+1 609-555-0142” | The telephone URL is built | The URL keeps the leading plus |
| TC4 | R3 | Integration | A charger and a restaurant are selected | Open in Apple Maps is tapped | The Maps request is a walking route from that charger to that restaurant |
| TC5 | R4 | Unit | The charger is at 40.33, -74.79 and the restaurant is at 40.32, -74.78 | The Google Maps URL is built | The URL contains those coordinates as origin and destination and `travelmode=walking` |
| TC6 | R5 | Unit | The restaurant is named “The Front Porch” | The Yelp URL is built | The URL searches for that name at the restaurant coordinate and has no route origin |

## Later unit-test notes

TC2, TC3, TC5, and TC6 can be functions on the detail model. TC4 needs a Maps launch spy or a manual check.
