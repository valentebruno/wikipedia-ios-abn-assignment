import CoreLocation
import Foundation

struct LocationsResponse: Decodable, Equatable {
    let locations: [LocationItem]
}

struct LocationItem: Identifiable, Decodable, Equatable, Hashable {
    let name: String
    let latitude: Double
    let longitude: Double

    var id: String {
        "\(name)|\(latitude)|\(longitude)"
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var coordinateDescription: String {
        String(format: "%.4f, %.4f", latitude, longitude)
    }

    init(name: String, latitude: Double, longitude: Double) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case latitude = "lat"
        case longitude = "long"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        let rawName = try container.decodeIfPresent(String.self, forKey: .name)

        self.latitude = latitude
        self.longitude = longitude
        self.name = Self.normalizedName(rawName, latitude: latitude, longitude: longitude)
    }

    private static func normalizedName(_ rawName: String?, latitude: Double, longitude: Double) -> String {
        if let rawName {
            let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }

        return String(format: "Unnamed location (%.4f, %.4f)", latitude, longitude)
    }
}
