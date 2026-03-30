# ABN AMRO iOS Assignment — Bruno Valente

PlacesLauncher is a SwiftUI app that fetches a list of locations and opens Wikipedia directly on its *Places* tab centered on a selected coordinate — not the user’s GPS position.

It also supports:
- custom coordinate input
- place search via geocoding

The implementation focuses on correctness, lifecycle robustness, and safe integration with an existing large codebase.

---

## Repository structure

```
├── PlacesLauncher/                       SwiftUI app (full Xcode project)
│   ├── PlacesLauncher.xcodeproj
│   └── PlacesLauncher/
│       ├── App/
│       ├── Models/
│       ├── Services/                    deep link builder, coordinate parser, geocoder
│       ├── ViewModels/                  @MainActor, async/await
│       ├── Views/                       SwiftUI + accessibility support
│       └── PlacesLauncherTests/         16 unit tests
│
└── wikipedia-ios/                       only modified files (minimal diff)
    ├── ABN_ASSIGNMENT_README.md         detailed technical walkthrough
    ├── Wikipedia/Code/
    │   ├── NSUserActivity+WMFExtensions.h/m   coordinate parsing
    │   ├── WMFAppViewController.m             deep link routing
    │   └── PlacesViewController.swift         showCoordinate() + GPS handling
    └── WikipediaUnitTests/Code/
        └── NSUserActivity+WMFExtensionsTest.m URL parsing tests
```

The `wikipedia-ios` folder contains only the modified files to keep the change set small and reviewable.

Full source: https://github.com/wikimedia/wikipedia-ios  
→ clone it, replace the files, and build.

---

## How it works

Wikipedia already supports:

```
wikipedia://places
```

This implementation extends it to accept coordinates:

```
wikipedia://places?lat=52.3676&lon=4.9041
```

Supported parameters:
- `lat` / `lon`
- `latitude` / `longitude`
- `lng` / `long`

Invalid values (non-numeric, out-of-range, incomplete pairs) are rejected before reaching the map.

PlacesLauncher constructs the URL and delegates execution to the OS.

---

## Running it

### Wikipedia

```bash
git clone https://github.com/wikimedia/wikipedia-ios.git
cd wikipedia-ios

cp -r /path/to/this-repo/wikipedia-ios/Wikipedia/Code/* Wikipedia/Code/
cp -r /path/to/this-repo/wikipedia-ios/WikipediaUnitTests/Code/* WikipediaUnitTests/Code/

open Wikipedia.xcodeproj
```

### PlacesLauncher

```bash
cd PlacesLauncher
open PlacesLauncher.xcodeproj
```

Run Wikipedia first (to register the URL scheme), then launch PlacesLauncher on the same simulator.

Tapping a location will open Wikipedia directly on the Places tab at the selected coordinate.

---

## Architecture decisions

PlacesLauncher follows a lightweight MVVM architecture focused on separation of concerns and testability:

- `@MainActor` ViewModels ensure UI thread safety  
- Business logic lives in Services (pure Swift, testable)  
- Parsing and validation are isolated from UI  
- Async flows use `async/await` with `.task` cancellation  

The Wikipedia app changes are intentionally minimal to reduce integration risk.

---

## Requirements

### Core functionality

| Requirement | Implementation |
|---|---|
| Fetch locations | `RemoteLocationsRepository` (`actor`) with timeouts and explicit error handling |
| Open Wikipedia on tap | `WikipediaDeepLinkBuilder` with lifecycle-safe routing (cold start + background) |
| Custom coordinates | `CoordinateParser` with validation and European format support |

### Architecture & quality

| Requirement | Implementation |
|---|---|
| SwiftUI | Fully SwiftUI (no UIKit, no storyboards) |
| Concurrency | `@MainActor`, `actor`, `async/await` |
| Unit tests | 16 PlacesLauncher tests + Wikipedia parsing tests |
| Accessibility | Full support with persistent settings (`@AppStorage`) |

---

## Tests

### PlacesLauncher — 16 unit tests

Covers core business logic and edge cases:

- JSON decoding  
- deep link construction  
- coordinate parsing  
- ViewModel state  
- geocoding success/failure  
- error handling  

```bash
cd PlacesLauncher
xcodebuild test \
  -scheme PlacesLauncher \
  -project PlacesLauncher.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

---

### Wikipedia — URL parsing tests

Covers:

- multiple parameter formats  
- invalid values  
- missing coordinate pairs  
- negative and boundary values (±90 / ±180)  

```bash
xcodebuild test \
  -project Wikipedia.xcodeproj \
  -scheme Wikipedia \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:WikipediaUnitTests/NSUserActivity_WMFExtensions_wmf_activityForWikipediaScheme_Test
```

---

## Accessibility

Accessibility is treated as a first-class concern:

- `accessibilityLabel`  
- `accessibilityHint`  

Coverage includes:
- lists, buttons, inputs  
- loading and error states  

In-app settings:
- larger text  
- higher contrast  
- reduced motion  
- VoiceOver coordinate reading  

All preferences persist via `@AppStorage`.

---

## Notable implementation details

### Cold launch vs background resume

- Cold start → URL captured via `connectionOptions.urlContexts`  
- Background → handled via `scene(_:openURLContexts:)`  

Both paths converge to a single handler, ensuring consistent behavior.

---

### GPS override prevention

Places normally auto-centers on the user’s location.

This is explicitly disabled for deep links:

- `panMapToNextLocationUpdate = false` is set before map updates  
- guarantees GPS cannot override the requested coordinate  

This behavior is deterministic by design.

---

### Coordinate validation

Validation happens in two independent layers:

1. URL parsing (`NSUserActivity`)  
2. UI coordination (`WMFPlacesDeepLinkCoordinator`)  

This prevents invalid data from propagating silently.

---

## Trade-offs

- Chose MVVM over heavier architectures to keep scope focused  
- Avoided persistence/caching to prevent over-engineering  
- Limited changes to Wikipedia to reduce regression risk  
- No UI tests due to time constraints (unit tests prioritized)  

---

## How to evaluate this project

Focus on:

- deep link reliability across lifecycle states  
- coordinate parsing robustness  
- separation of concerns  
- test coverage of edge cases  
- accessibility completeness  

---

## Final notes

This implementation prioritizes:

- correctness in deep link handling and coordinate validation  
- clarity in architecture and separation of concerns  
- minimal, safe integration with the existing Wikipedia codebase  
