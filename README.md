# ABN AMRO iOS Assignment — Bruno Valente

This repository contains everything for the assignment: a modified Wikipedia iOS app and a SwiftUI companion app called PlacesLauncher.

The idea is simple. PlacesLauncher shows a list of locations fetched from a remote endpoint. Tap one, and Wikipedia opens directly on its Places tab, centered on that coordinate — not on the user's current GPS position. The user can also type in any custom coordinate or search for a place by name.

---

## Repository structure

```
README.md                        ← you are here
PlacesLauncher/                  ← the SwiftUI test app (full project)
wikipedia-ios/
  ABN_ASSIGNMENT_README.md       ← detailed notes on what changed and why
  Wikipedia/Code/
    NSUserActivity+WMFExtensions.h / .m   ← coordinate parsing added here
    WMFAppViewController.m                ← deep link routing added here
    PlacesViewController.swift            ← showCoordinate() added here
  WikipediaUnitTests/Code/
    NSUserActivity+WMFExtensionsTest.m    ← new tests added here
```

The `wikipedia-ios` folder contains only the files that were changed. The full Wikipedia iOS source is at [github.com/wikimedia/wikipedia-ios](https://github.com/wikimedia/wikipedia-ios) — clone that, drop these files in, and it builds.

---

## The deep link

Wikipedia already had a `wikipedia://places` route for opening Places from a stored article URL. This assignment extends it to accept raw coordinates:

```
wikipedia://places?lat=52.3676&lon=4.9041
```

PlacesLauncher builds that URL, hands it to the OS, and Wikipedia handles the rest. Both `lat`/`lon` and `latitude`/`longitude`/`lng`/`long` are accepted. Out-of-range and non-numeric values are rejected before they reach the map.

---

## Running it

You need the Wikipedia iOS source to run the modified Wikipedia app.

```bash
# Clone the Wikipedia source
git clone https://github.com/wikimedia/wikipedia-ios.git
cd wikipedia-ios

# Drop in the modified files
cp -r /path/to/this-repo/wikipedia-ios/Wikipedia/Code/* Wikipedia/Code/
cp -r /path/to/this-repo/wikipedia-ios/WikipediaUnitTests/Code/* WikipediaUnitTests/Code/

# Open in Xcode
open Wikipedia.xcodeproj
```

The PlacesLauncher Xcode project is committed directly so you can open it right away:

```bash
cd PlacesLauncher
open PlacesLauncher.xcodeproj
```

If you ever need to regenerate it from `project.yml`, install [XcodeGen](https://github.com/yonaskolb/XcodeGen) and run:

```bash
brew install xcodegen
cd PlacesLauncher
xcodegen generate
```

Run Wikipedia first (so it registers the URL scheme), then run PlacesLauncher on the **same simulator**. Tap a location — Wikipedia should jump to Places at that coordinate.

For a complete walkthrough of the changes and the reasoning behind them, see [`wikipedia-ios/ABN_ASSIGNMENT_README.md`](wikipedia-ios/ABN_ASSIGNMENT_README.md).

---

## Assignment requirements checklist

| Requirement | Notes |
|---|---|
| Fetch locations from the JSON endpoint | `RemoteLocationsRepository` actor fetches from the single ABN AMRO endpoint with a 15 s request / 30 s resource timeout. Decodes the JSON and surfaces errors clearly rather than silently retrying a broken fallback. |
| Tap a location → Wikipedia opens Places at that coordinate | `WikipediaDeepLinkBuilder` constructs `wikipedia://places?lat=…&lon=…`. Both cold launch and background-resume paths are handled correctly. |
| Custom coordinate entry | Coordinate text field in PlacesLauncher. `CoordinateParser` handles comma as decimal separator (European keyboards), validates range before opening. |
| SwiftUI for the Places app | PlacesLauncher is built entirely in SwiftUI. No UIKit, no storyboards. The `.xcodeproj` is committed so reviewers can open it directly without installing XcodeGen. |
| README | This file, plus `wikipedia-ios/ABN_ASSIGNMENT_README.md` with a detailed walkthrough of all Wikipedia changes and the decisions behind them. |
| Unit tests | 16 tests in PlacesLauncher covering JSON decoding, deep link construction, coordinate parsing, ViewModel state transitions, geocoding, and error handling. Additional Objective-C tests in `NSUserActivity+WMFExtensionsTest.m` covering the Wikipedia URL parsing changes. |
| Swift Concurrency | ViewModel is `@MainActor` — every `@Published` update runs on the main thread with no manual dispatch calls. Repository is an `actor`. All network calls use `async/await`. Views use `.task {}` so work cancels automatically when the view disappears. |
| Accessibility | Every button, list row, text field, and loading/error state has an `accessibilityLabel` and `accessibilityHint`. An in-app settings panel lets the user enable larger text, higher contrast, reduced motion, and VoiceOver coordinate reading — all persisted via `@AppStorage`. |

---

## PlacesLauncher — what's inside

The app is organised in clean layers so each piece is independently testable:

- **Domain** — `Location` model, `LocationsRepository` protocol
- **Data** — `RemoteLocationsRepository` (URLSession, async/await, 15s timeout)
- **Presentation** — `@MainActor` ViewModel with typed `ViewState` enum, SwiftUI views
- **Infrastructure** — `WikipediaDeepLinkBuilder`, `CoordinateParser`, `ExternalAppOpener`

**Swift Concurrency** is used throughout: the ViewModel is `@MainActor` so every `@Published` update runs on the main thread without manual dispatch calls. The repository is an `actor`. Network calls use `async/await`. Views use `.task {}` so async work cancels automatically when the view disappears.

**Accessibility** — every button, list row, text field, and loading state has an `accessibilityLabel` and `accessibilityHint`. There is also an in-app settings panel that lets the user switch on larger text, higher contrast, reduced motion, and VoiceOver coordinate reading — all persisted with `@AppStorage`.

---

## Tests

### PlacesLauncher unit tests (16)

```bash
cd PlacesLauncher
xcodebuild test \
  -scheme PlacesLauncher \
  -project PlacesLauncher.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Covers JSON decoding, deep link URL building, coordinate parsing (including European comma separator), coordinate range validation, ViewModel state transitions, Wikipedia-unavailable error, geocoding success and failure.

### Wikipedia deep link tests

```bash
# from the full wikipedia-ios repo root
xcodebuild test \
  -project Wikipedia.xcodeproj \
  -scheme Wikipedia \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:WikipediaUnitTests/NSUserActivity_WMFExtensions_wmf_activityForWikipediaScheme_Test
```

Covers `lat`/`lon` parsing, alternate param names, non-numeric values, out-of-range values, partial pairs, negative coordinates, boundary values (90/180).

---

## A few things worth noting

**Cold launch vs background resume** — both paths work. When the app is not running, `SceneDelegate` picks up the URL from `connectionOptions.urlContexts` and stores it until the UI is ready. When the app is backgrounded, `scene(_:openURLContexts:)` fires directly. Both funnel to the same handler.

**The GPS race** — Places normally auto-centres on the user's GPS position when it appears. `showCoordinate()` sets `panMapToNextLocationUpdate = false` before calling `performDefaultSearch`, which blocks any incoming GPS update from overriding the deep-linked position. This runs on the main thread so there is no actual race — it's deterministic.

**Coordinate validation** — validation happens at parse time in `wmf_placesActivityWithURL:` (before values enter `NSUserActivity.userInfo`) and again in `WMFPlacesDeepLinkCoordinator` before the map is moved. Two layers, so a bug in one doesn't silently show a wrong location.
