@Metadata {
    @PageKind(article)
}

# Architecture

## Overview

The app is intentionally split into focused layers so each concern is isolated and easily testable.

## Structure

### Views

- `LocationsListView` renders loading, failure, and loaded states.
- `CustomCoordinateView` captures custom latitude and longitude values.

### ViewModel

- `LocationsViewModel` is `@MainActor` and coordinates UI state transitions.
- It does not perform parsing, URL construction, or UIKit app launching directly.

### Services

- `RemoteLocationsRepository` (`actor`) fetches and decodes locations from remote endpoints.
- `WikipediaDeepLinkBuilder` builds and validates Wikipedia Places deep-link URLs.
- `CoordinateParser` converts user-entered text into valid coordinates.
- `UIApplicationExternalAppOpener` opens external URLs using async/await.

## Why this design

- Protocol boundaries keep the code testable with lightweight mocks.
- Actor isolation keeps network-related state and behavior concurrency-safe.
- UI mutations stay on the main actor, improving correctness and readability.
