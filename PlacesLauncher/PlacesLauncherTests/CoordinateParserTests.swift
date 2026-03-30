import CoreLocation
import XCTest
@testable import PlacesLauncher

final class CoordinateParserTests: XCTestCase {
    func test_parse_withValidDecimalValues_returnsCoordinate() {
        let sut = CoordinateParser()

        let coordinate = sut.parse(latitudeText: "52.3676", longitudeText: "4.9041")

        guard let parsed = coordinate else {
            XCTFail("Expected coordinate to be parsed")
            return
        }

        XCTAssertEqual(parsed.latitude, 52.3676, accuracy: 0.0001)
        XCTAssertEqual(parsed.longitude, 4.9041, accuracy: 0.0001)
    }

    func test_parse_withCommaDecimalSeparator_returnsCoordinate() {
        let sut = CoordinateParser()

        let coordinate = sut.parse(latitudeText: "52,3676", longitudeText: "4,9041")

        guard let parsed = coordinate else {
            XCTFail("Expected coordinate to be parsed")
            return
        }

        XCTAssertEqual(parsed.latitude, 52.3676, accuracy: 0.0001)
        XCTAssertEqual(parsed.longitude, 4.9041, accuracy: 0.0001)
    }

    func test_parse_withOutOfRangeCoordinate_returnsNil() {
        let sut = CoordinateParser()

        let coordinate = sut.parse(latitudeText: "999", longitudeText: "4.9041")

        XCTAssertNil(coordinate)
    }
}
