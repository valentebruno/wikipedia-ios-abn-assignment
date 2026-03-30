import XCTest
@testable import PlacesLauncher

final class LocationDecodingTests: XCTestCase {
    func test_decodingValidPayload_decodesAllLocations() throws {
        let json = """
        {
          "locations": [
            { "name": "Amsterdam", "lat": 52.3547498, "long": 4.8339215 },
            { "name": "Mumbai", "lat": 19.0823998, "long": 72.8111468 }
          ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(LocationsResponse.self, from: json)

        XCTAssertEqual(response.locations.count, 2)
        XCTAssertEqual(response.locations.first?.name, "Amsterdam")
    }

    func test_decodingLocationWithoutName_appliesFallbackName() throws {
        let json = """
        {
          "locations": [
            { "lat": 40.4380638, "long": -3.7495758 }
          ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(LocationsResponse.self, from: json)
        let location = try XCTUnwrap(response.locations.first)

        XCTAssertEqual(location.name, "Unnamed location (40.4381, -3.7496)")
    }

    func test_decodingMalformedPayload_throws() {
        let malformedJSON = "not json".data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(LocationsResponse.self, from: malformedJSON))
    }
}
