import CoreLocation
import XCTest
@testable import PlacesLauncher

final class WikipediaDeepLinkBuilderTests: XCTestCase {
    func test_makePlacesURL_validCoordinate_buildsExpectedURL() throws {
        let sut = WikipediaDeepLinkBuilder()
        let coordinate = CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041)

        let url = try sut.makePlacesURL(coordinate: coordinate)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))

        XCTAssertEqual(components.scheme, "wikipedia")
        XCTAssertEqual(components.host, "places")
        XCTAssertEqual(queryValue("lat", in: components), "52.367600")
        XCTAssertEqual(queryValue("lon", in: components), "4.904100")
    }

    func test_makePlacesURL_invalidCoordinate_throws() {
        let sut = WikipediaDeepLinkBuilder()
        let coordinate = CLLocationCoordinate2D(latitude: 200, longitude: 4.9041)

        XCTAssertThrowsError(try sut.makePlacesURL(coordinate: coordinate)) { error in
            XCTAssertEqual(error as? WikipediaDeepLinkError, .invalidCoordinate)
        }
    }

    private func queryValue(_ name: String, in components: URLComponents) -> String? {
        components.queryItems?.first(where: { $0.name == name })?.value
    }
}
