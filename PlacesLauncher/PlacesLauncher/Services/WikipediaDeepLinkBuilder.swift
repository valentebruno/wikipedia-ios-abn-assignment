import CoreLocation
import Foundation

protocol WikipediaDeepLinkBuilding {
    func makePlacesURL(coordinate: CLLocationCoordinate2D) throws -> URL
}

enum WikipediaDeepLinkError: Error, Equatable {
    case invalidCoordinate
    case urlCreationFailed
}

extension WikipediaDeepLinkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidCoordinate:
            return "Please enter valid coordinates (latitude -90...90, longitude -180...180)."
        case .urlCreationFailed:
            return "Could not create a Wikipedia deep link URL."
        }
    }
}

struct WikipediaDeepLinkBuilder: WikipediaDeepLinkBuilding {
    func makePlacesURL(coordinate: CLLocationCoordinate2D) throws -> URL {
        guard coordinate.isInValidRange else {
            throw WikipediaDeepLinkError.invalidCoordinate
        }

        var components = URLComponents()
        components.scheme = "wikipedia"
        components.host = "places"
        components.queryItems = [
            URLQueryItem(name: "lat", value: formattedCoordinateValue(coordinate.latitude)),
            URLQueryItem(name: "lon", value: formattedCoordinateValue(coordinate.longitude))
        ]

        guard let url = components.url else {
            throw WikipediaDeepLinkError.urlCreationFailed
        }
        return url
    }

    private func formattedCoordinateValue(_ value: Double) -> String {
        String(format: "%.6f", value)
    }
}
