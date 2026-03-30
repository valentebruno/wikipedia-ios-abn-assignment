import Foundation

struct UITestLocationsRepository: LocationsRepository {
    func fetchLocations() async throws -> [LocationItem] {
        [
            LocationItem(name: "Amsterdam", latitude: 52.3547, longitude: 4.8339),
            LocationItem(name: "Mumbai", latitude: 19.0824, longitude: 72.8111),
            LocationItem(name: "Copenhagen", latitude: 55.6712, longitude: 12.5238)
        ]
    }
}

struct UITestExternalAppOpener: ExternalAppOpening {
    func open(_ url: URL) async throws {
        _ = url
    }
}

struct UITestLocationGeocoder: LocationGeocoding {
    func geocodeLocation(named query: String) async throws -> LocationItem {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw LocationGeocodingError.emptyQuery
        }

        // Deterministic result for UI tests.
        return LocationItem(name: "\(trimmed) (Geocoded)", latitude: 38.7223, longitude: -9.1393)
    }
}
