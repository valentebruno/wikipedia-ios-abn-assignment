# ABN AMRO iOS Assignment — Bruno Valente

PlacesLauncher is a SwiftUI app that fetches a list of locations and, on tap, opens Wikipedia directly on its Places tab centred on that coordinate — not the user's current GPS position. The user can also enter a custom coordinate or search for any place by name.

---

## Repository structure

```
PlacesLauncher/                       SwiftUI app (full Xcode project)
wikipedia-ios/
  ABN_ASSIGNMENT_README.md            detailed walkthrough of every change
  Wikipedia/Code/
    NSUserActivity+WMFExtensions.h/m  coordinate parsing from the URL scheme
    WMFAppViewController.m            deep link routing to Places
    PlacesViewController.swift        showCoordinate() and GPS-race fix
  WikipediaUnitTests/Code/
    NSUserActivity+WMFExtensionsTest.m  new URL-parsing tests
```

The `wikipedia-ios` folder contains only the files that were changed. The full source is at [github.com/wikimedia/wikipedia-ios](https://github.com/wikimedia/wikipedia-ios) — clone it, drop these files in, and it builds.

---

## How it works

Wikipedia already had a `wikipedia://places` route for opening Places from an article URL. This assignment extends it to accept raw coordinates:

```
wikipedia://places?lat=52.3676&lon=4.9041
```

PlacesLauncher builds that URL and hands it to the OS. Both `lat`/`lon` and the longer `latitude`/`longitude`/`lng`/`long` forms are accepted. Out-of-range and non-numeric values are rejected before they reach the map.

---

## Running it

**Wikipedia**

```bash
git clone https://github.com/wikimedia/wikipedia-ios.git
cd wikipedia-ios

cp -r /path/to/this-repo/wikipedia-ios/Wikipedia/Code/* Wikipedia/Code/
cp -r /path/to/this-repo/wikipedia-ios/WikipediaUnitTests/Code/* WikipediaUnitTests/Code/

open Wikipedia.xcodeproj
```

**PlacesLauncher**

The `.xcodeproj` is committed — open it directly:

```bash
cd PlacesLauncher
open PlacesLauncher.xcodeproj
```

Run Wikipedia first so it registers the URL scheme, then run PlacesLauncher on the **same simulator**. Tap a location — Wikipedia should jump to Places at that coordinate.

For a full walkthrough of the Wikipedia changes and the decisions behind them, see [`wikipedia-ios/ABN_ASSIGNMENT_README.md`](wikipedia-ios/ABN_ASSIGNMENT_README.md).

---

## Requirements

| Requirement | Notes |
|---|---|
| Fetch locations from the JSON endpoint | `RemoteLocationsRepository` actor hits the single ABN AMRO endpoint with a 15 s / 30 s timeout and surfaces errors clearly. |
| Tap a location → Wikipedia opens Places at that coordinate | `WikipediaDeepLinkBuilder` constructs the URL. Both cold-launch and background-resume paths work. |
| Custom coordinate entry | `CoordinateParser` accepts comma as decimal separator (European keyboards) and validates range before opening. |
| SwiftUI for the Places app | PlacesLauncher is pure SwiftUI — no UIKit, no storyboards. |
| README | This file, plus `wikipedia-ios/ABN_ASSIGNMENT_README.md` with detailed technical notes. |
| Unit tests | 16 PlacesLauncher tests (JSON decoding, deep link construction, coordinate parsing, ViewModel state, geocoding, error handling) and new Objective-C tests for the Wikipedia URL-parsing changes. |
| Swift Concurrency | `@MainActor` ViewModel, `actor` repository, `async/await` throughout, `.task` for automatic cancellation on view disappear. |
| Accessibility | `accessibilityLabel` and `accessibilityHint` on every interactive element. In-app settings panel for larger text, higher contrast, reduced motion, and VoiceOver coordinate reading — persisted with `@AppStorage`. |

---

## Tests

**PlacesLauncher**

```bash
cd PlacesLauncher
xcodebuild test \
  -scheme PlacesLauncher \
  -project PlacesLauncher.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

**Wikipedia deep link parsing** (run from the full wikipedia-ios repo root)

```bash
xcodebuild test \
  -project Wikipedia.xcodeproj \
  -scheme Wikipedia \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:WikipediaUnitTests/NSUserActivity_WMFExtensions_wmf_activityForWikipediaScheme_Test
```

---

## Notable implementation details

**Cold launch and background resume** — when Wikipedia is not running, `SceneDelegate` picks up the URL from `connectionOptions.urlContexts` and stores it until the UI is ready. When it is backgrounded, `scene(_:openURLContexts:)` fires directly. Both paths reach the same handler.

**The GPS race** — Places normally auto-centres on the user's position when it appears. `showCoordinate()` sets `panMapToNextLocationUpdate = false` before calling `performDefaultSearch`. Because this runs synchronously on the main thread, any GPS update that arrives before or after will return early without overriding the deep-linked coordinate.

**Coordinate validation** — validation runs at parse time in `wmf_placesActivityWithURL:` (before values enter `NSUserActivity.userInfo`) and again in `WMFPlacesDeepLinkCoordinator` before the map moves. Two independent layers, so a bug in one cannot silently display a wrong location.
