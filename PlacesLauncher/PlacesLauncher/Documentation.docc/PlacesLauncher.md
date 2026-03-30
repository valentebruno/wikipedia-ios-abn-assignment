# ``PlacesLauncher``

@Metadata {
    @TechnologyRoot
}

## Overview

`PlacesLauncher` is the assignment test app used to open the Wikipedia iOS app directly on the Places tab with explicit coordinates.

The app:

- Fetches a remote list of locations.
- Opens `wikipedia://places?lat=...&lon=...` when a location is selected.
- Allows entering custom coordinates and opening Wikipedia at that coordinate.
- Uses modern Swift concurrency and protocol-driven boundaries for testability.

## Topics

### Guides

- <doc:Architecture>
- <doc:Run-And-Validate>
