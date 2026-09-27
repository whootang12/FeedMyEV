# Charger data

Status: Implemented

Code: `FeedMyEVTrip/Features/Settings/ChargerDataView.swift`, `FeedMyEVTrip/Services/AFDCChargerProvider.swift`

Preferences → Charger Data shows the local catalog and can refresh it with a personal AFDC API key. The key stays in the device Keychain.

## Requirements

### R1. Display

The screen shows the source as AFDC, the station count, and the download date when one exists. A provider warning is shown. A refresh in progress shows progress and disables the refresh actions.

### R2. Key storage

Saving a key trims whitespace, rejects an empty key, and stores it in the Keychain for this app. The key is not written into the repository or the catalog file. Replacing a key updates the existing Keychain item.

### R3. Manual refresh

Refresh catalog requires a stored key. Save key and download stores the entered key, then downloads. The download requests all U.S. public, available, DC-fast electric stations.

### R4. One download

Overlapping refresh callers share one download task.

### R5. Atomic replacement

The response is validated before the file is replaced. An unauthorized, rate-limited, unavailable, or incomplete response leaves the previous catalog in place. A successful download clears the warning, updates the count and date, and drops the in-memory charger cache.

### R6. Error text

Missing key, unauthorized, rate limited, unavailable, incomplete, and key-storage failures use the messages on `AFDCCatalogError`. A failed manual refresh says the previous catalog was kept.

## Test cases

| ID | Covers | Type | Given | When | Then |
| --- | --- | --- | --- | --- | --- |
| TC1 | R2 | Unit | The entered key is blank or spaces | Save is attempted | It fails as a missing key and the Keychain is unchanged |
| TC2 | R2 | Unit | A key is already stored | A new non-empty key is saved | The stored key is the new value and there is still one item |
| TC3 | R3 | Integration | No key is stored | The screen is shown | Refresh catalog is disabled, and Save key and download is disabled until text is entered |
| TC4 | R4 | Unit | Two refreshes start together | Both wait | One network request runs and both callers finish with the same result |
| TC5 | R5 | Unit | A valid catalog is already stored | The response is HTTP 200 with a mismatched `total_results` | The stored stations and file are unchanged |
| TC6 | R5 | Unit | A valid catalog is already stored | The response is HTTP 401, 429, or 500 | The error is unauthorized, rate limited, or unavailable, and the stored stations remain |
| TC7 | R5 | Unit | A valid catalog is already stored | A complete catalog downloads | The new stations replace the old ones and the charger cache is cleared |
| TC8 | R6 | Unit | Each `AFDCCatalogError` case is thrown | Its localized description is read | The text matches the case’s message and tells the user where to act when a key is involved |

## Later unit-test notes

Key tests need a test Keychain or a store protocol. Download tests can use a stub response and a temporary file URL.
