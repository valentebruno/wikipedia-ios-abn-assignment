@Metadata {
    @PageKind(article)
}

# Run And Validate

## Generate Project

`PlacesLauncher` is generated with XcodeGen.

```bash
cd /Users/brunovalente/Developer/ABN-AMroTest/code/wikipedia-ios/PlacesLauncher
xcodegen generate
```

## Run Tests

```bash
xcodebuild test \
  -scheme PlacesLauncher \
  -project /Users/brunovalente/Developer/ABN-AMroTest/code/wikipedia-ios/PlacesLauncher/PlacesLauncher.xcodeproj \
  -destination id=73FD14F5-4F97-460A-A9C5-39F4E48CC6C9
```

## Manual Flow Check

1. Launch Wikipedia and PlacesLauncher on the same simulator.
2. Tap a location in PlacesLauncher.
3. Confirm Wikipedia opens on the Places tab at the expected coordinate.
4. Enter a custom coordinate and open again.
5. Repeat while Wikipedia is backgrounded to validate resume behavior.

## Deep-Link Contract

- Coordinate format:
  `wikipedia://places?lat={latitude}&lon={longitude}`
- Existing article-link behavior remains supported through the Wikipedia-side routing changes.
