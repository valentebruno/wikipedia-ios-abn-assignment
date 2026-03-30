# ABN AMRO iOS Assignment

This repo covers both parts of the assignment: a modified Wikipedia iOS app that opens its Places tab at any coordinate you send it, and a small SwiftUI companion app (PlacesLauncher) that does the sending.

---

## How it works

The Wikipedia app already supports being opened from other apps via the `wikipedia://` URL scheme. What it didn't have was a way to say "open Places at *this* coordinate" rather than whatever the user's current GPS position is.

The new route looks like this:

```
wikipedia://places?lat=52.3676&lon=4.9041
```

PlacesLauncher builds that URL, hands it to the OS, and Wikipedia wakes up on the Places tab showing that exact spot on the map — not the user's current location.

---

## Project structure

```
wikipedia-ios/               ← modified Wikipedia app (Wikimedia fork)
└── PlacesLauncher/          ← the SwiftUI test app (XcodeGen project)
```

Both live in the same repo so you only need to clone once.

---

## Running it

You need two simulators running at the same time — or one, if you switch between apps.

**Step 1 — Wikipedia**

Open `Wikipedia.xcodeproj` in Xcode, select the `Wikipedia` scheme, and run it on an iPhone simulator. Let it finish launching at least once so it registers the `wikipedia://` URL scheme with the OS.

**Step 2 — PlacesLauncher**

The PlacesLauncher project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen). If you don't have it:

```bash
brew install xcodegen
```

Then generate and open:

```bash
cd PlacesLauncher
xcodegen generate
open PlacesLauncher.xcodeproj
```

Select the `PlacesLauncher` scheme and run it on the **same simulator**.

**Step 3 — Test the flow**

1. In PlacesLauncher, tap any location from the list
2. Wikipedia should come to the foreground and land on Places, centred on that coordinate
3. Press Home, go back to PlacesLauncher, tap a different location — Wikipedia should update again (this is the background-resume path, which is easy to miss)
4. Tap "Custom Coordinates" in the toolbar, type in any lat/lon, tap Open

---

## What changed in Wikipedia

The original app already had `wikipedia://places` for opening Places from a stored article URL. It had no route for raw coordinates.

**`NSUserActivity+WMFExtensions.m`**

Extended `wmf_placesActivityWithURL:` to parse coordinate query params (`lat`, `lon`, and also `latitude`, `longitude`, `lng`, `long` for flexibility). Invalid strings and out-of-range values are rejected at parse time so they never reach the map layer.

**`WMFAppViewController.m`**

Added `WMFPlacesDeepLinkCoordinator` — a small focused class that sits between the URL handler and the Places view controller. When a Places activity arrives, it extracts the coordinates and tells `PlacesViewController` where to look. If there are no coordinates but there is an article URL, it falls back to the existing article-based behaviour.

**`PlacesViewController.swift`**

Added `showCoordinate(latitude:longitude:)`. The tricky part here is that Places normally auto-centres on the user's GPS position when it appears. To prevent the deep-linked coordinate from being overridden, the method sets `panMapToNextLocationUpdate = false` before calling `performDefaultSearch`. Because this all runs synchronously on the main thread, there's no race — the coordinate always wins regardless of whether a GPS update arrives before or after.

---

## PlacesLauncher

A clean SwiftUI app built with a simple layered structure.

```
Domain/      Location model, LocationsRepository protocol
Data/        RemoteLocationsRepository (URLSession + async/await)
Presentation/  LocationsViewModel (@MainActor), views
Infrastructure/  WikipediaDeepLinkBuilder, CoordinateParser, ExternalAppOpener
```

**Features**

- Fetches locations from the assignment JSON endpoint
- Tap a location → opens Wikipedia Places at that coordinate
- Search bar filters the list by name
- Geocoding: type any place name, resolve it to coordinates, open it
- Custom coordinate entry (accepts comma as decimal separator for European keyboards)
- Accessibility labels and hints on every interactive element
- Accessibility settings panel (larger text, higher contrast, reduce motion, VoiceOver coordinate reading)

**Swift Concurrency**

The ViewModel is `@MainActor`, so every `@Published` update is guaranteed to run on the main thread without any manual `DispatchQueue.main.async` calls. The repository is an `actor`. Async work in views uses `.task {}` which ties the lifecycle to the view and cancels automatically on disappear.

---

## Tests

### PlacesLauncher

```bash
cd PlacesLauncher
xcodebuild test \
  -scheme PlacesLauncher \
  -project PlacesLauncher.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Covers: JSON decoding (including missing-name fallback), deep link URL construction, coordinate parsing (including European comma separator), coordinate validation, ViewModel state transitions, Wikipedia-unavailable handling, geocoding success and failure.

### Wikipedia deep link parsing

```bash
xcodebuild test \
  -project Wikipedia.xcodeproj \
  -scheme Wikipedia \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:WikipediaUnitTests/NSUserActivity_WMFExtensions_wmf_activityForWikipediaScheme_Test
```

Covers: `lat`/`lon` parsing, alternate param names, invalid strings, out-of-range coordinates, missing-only-one-coordinate rejection, negative coordinates, boundary values.

---

## Decisions worth explaining

**Why `WMFPlacesDeepLinkCoordinator` instead of putting everything in `WMFAppViewController`?**

`WMFAppViewController` is already a very large file. Pulling the Places deep-link logic into its own object makes it easy to find, test in isolation conceptually, and change without touching the surrounding routing code. The alternative would have been `NotificationCenter`, but that makes the data flow harder to trace in a codebase this size.

**Why validate coordinates at parse time in `wmf_placesActivityWithURL:` if `WMFPlacesDeepLinkCoordinator` already validates them?**

Defence in depth. If the coordinate is obviously wrong (lat=999), there's no reason to store it in `NSUserActivity.userInfo` at all. Catching it early keeps the activity object clean and means the failure is visible at the point where bad data entered the system, not somewhere downstream.

**Why 15 seconds for the URLSession timeout?**

The default is 60 seconds, which means a stalled request holds a loading spinner for a full minute. 15 seconds is long enough for a slow connection and short enough to show the error state before the user gives up.

**The `panMapToNextLocationUpdate` flag**

This is the cleanest way to win the GPS race. Setting it to `false` before calling `performDefaultSearch` means any GPS delegate callback that arrives — before or after — will return early without overriding the map region. A `DispatchQueue.main.asyncAfter` delay also works but it is timing-dependent and looks like a hack. The flag approach is deterministic.
