import CoreLocation
import Foundation

protocol LocationGeocoding {
    func geocodeLocation(named query: String) async throws -> LocationItem
}

enum LocationGeocodingError: Error, Equatable {
    case emptyQuery
    case noMatchFound
    case invalidCoordinate
    case lookupFailed
}

extension LocationGeocodingError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .emptyQuery:
            return "Please enter a location name to search."
        case .noMatchFound:
            return "No location was found for that search."
        case .invalidCoordinate:
            return "The geocoding result included invalid coordinates."
        case .lookupFailed:
            return "Could not search that location right now."
        }
    }
}

final class CLGeocoderLocationGeocoder: LocationGeocoding {
    private let geocoder: CLGeocoder

    init(geocoder: CLGeocoder = CLGeocoder()) {
        self.geocoder = geocoder
    }

    func geocodeLocation(named query: String) async throws -> LocationItem {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            throw LocationGeocodingError.emptyQuery
        }

        let placemarks: [CLPlacemark]
        do {
            placemarks = try await geocodeAddressString(trimmedQuery)
        } catch {
            throw LocationGeocodingError.lookupFailed
        }

        guard let placemark = placemarks.first,
              let coordinate = placemark.location?.coordinate else {
            throw LocationGeocodingError.noMatchFound
        }
        guard coordinate.isInValidRange else {
            throw LocationGeocodingError.invalidCoordinate
        }

        let displayName = buildDisplayName(from: placemark, fallback: trimmedQuery)
        return LocationItem(
            name: displayName,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }

    private func geocodeAddressString(_ query: String) async throws -> [CLPlacemark] {
        try await withCheckedThrowingContinuation { continuation in
            geocoder.geocodeAddressString(query) { placemarks, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: placemarks ?? [])
            }
        }
    }

    private func buildDisplayName(from placemark: CLPlacemark, fallback: String) -> String {
        let candidates = [
            placemark.name,
            placemark.locality,
            placemark.subAdministrativeArea,
            placemark.administrativeArea,
            placemark.country
        ]

        var seenKeys = Set<String>()
        var parts: [String] = []
        for candidate in candidates {
            guard let candidate else {
                continue
            }
            let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                continue
            }
            let normalizedKey = trimmed.lowercased()
            guard seenKeys.insert(normalizedKey).inserted else {
                continue
            }
            parts.append(trimmed)
        }

        guard !parts.isEmpty else {
            return fallback
        }
        return parts.joined(separator: ", ")
    }
}
