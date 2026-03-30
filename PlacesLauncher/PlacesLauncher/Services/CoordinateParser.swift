import CoreLocation
import Foundation

protocol CoordinateParsing {
    func parse(latitudeText: String, longitudeText: String) -> CLLocationCoordinate2D?
}

struct CoordinateParser: CoordinateParsing {
    func parse(latitudeText: String, longitudeText: String) -> CLLocationCoordinate2D? {
        guard let latitude = parseNumber(latitudeText),
              let longitude = parseNumber(longitudeText) else {
            return nil
        }

        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        return coordinate.isInValidRange ? coordinate : nil
    }

    private func parseNumber(_ rawText: String) -> Double? {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }
}
