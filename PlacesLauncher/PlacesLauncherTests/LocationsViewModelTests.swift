import CoreLocation
import XCTest
@testable import PlacesLauncher

@MainActor
final class LocationsViewModelTests: XCTestCase {
    func test_loadLocations_success_updatesStateAndLocations() async {
        let expectedLocations = [
            LocationItem(name: "Amsterdam", latitude: 52.3676, longitude: 4.9041)
        ]
        let sut = LocationsViewModel(
            repository: MockLocationsRepository(result: .success(expectedLocations)),
            deepLinkBuilder: MockDeepLinkBuilder(result: .failure(MockError())),
            appOpener: MockAppOpener()
        )

        await sut.loadLocations()

        XCTAssertEqual(sut.loadState, .loaded)
        XCTAssertEqual(sut.locations, expectedLocations)
    }

    func test_loadLocations_failure_updatesFailedState() async {
        let sut = LocationsViewModel(
            repository: MockLocationsRepository(result: .failure(MockError())),
            deepLinkBuilder: MockDeepLinkBuilder(result: .failure(MockError())),
            appOpener: MockAppOpener()
        )

        await sut.loadLocations()

        if case .failed = sut.loadState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected loadState to be .failed")
        }
    }

    func test_openWikipedia_success_opensExpectedURL() async {
        let expectedURL = URL(string: "wikipedia://places?lat=52.367600&lon=4.904100")!
        let opener = MockAppOpener()
        let sut = LocationsViewModel(
            repository: MockLocationsRepository(result: .success([])),
            deepLinkBuilder: MockDeepLinkBuilder(result: .success(expectedURL)),
            appOpener: opener
        )

        let location = LocationItem(name: "Amsterdam", latitude: 52.3676, longitude: 4.9041)
        let didOpen = await sut.openWikipedia(for: location)

        XCTAssertTrue(didOpen)
        XCTAssertEqual(opener.openedURLs, [expectedURL])
    }

    func test_openCustomCoordinate_invalidInput_setsAlertAndReturnsFalse() async {
        let sut = LocationsViewModel(
            repository: MockLocationsRepository(result: .success([])),
            deepLinkBuilder: MockDeepLinkBuilder(result: .failure(MockError())),
            appOpener: MockAppOpener()
        )
        sut.customLatitude = "abc"
        sut.customLongitude = "4.9"

        let didOpen = await sut.openCustomCoordinate()

        XCTAssertFalse(didOpen)
        XCTAssertNotNil(sut.alertMessage)
    }

    func test_openWikipedia_whenAppUnavailable_setsAlertAndReturnsFalse() async {
        let expectedURL = URL(string: "wikipedia://places?lat=52.367600&lon=4.904100")!
        let opener = MockAppOpener(error: ExternalAppOpenError.appUnavailable)
        let sut = LocationsViewModel(
            repository: MockLocationsRepository(result: .success([])),
            deepLinkBuilder: MockDeepLinkBuilder(result: .success(expectedURL)),
            appOpener: opener
        )
        let location = LocationItem(name: "Amsterdam", latitude: 52.3676, longitude: 4.9041)

        let didOpen = await sut.openWikipedia(for: location)

        XCTAssertFalse(didOpen)
        XCTAssertEqual(opener.openedURLs.count, 0)
        XCTAssertNotNil(sut.alertMessage)
    }

    func test_searchLocationByName_success_setsFoundStateAndCoordinates() async {
        let geocodedLocation = LocationItem(name: "Lisbon", latitude: 38.7223, longitude: -9.1393)
        let sut = LocationsViewModel(
            repository: MockLocationsRepository(result: .success([])),
            deepLinkBuilder: MockDeepLinkBuilder(result: .failure(MockError())),
            appOpener: MockAppOpener(),
            geocoder: MockLocationGeocoder(result: .success(geocodedLocation))
        )
        sut.updateLocationSearchQuery("Lisbon")

        let didFind = await sut.searchLocationByName()

        XCTAssertTrue(didFind)
        XCTAssertEqual(sut.customLatitude, "38.722300")
        XCTAssertEqual(sut.customLongitude, "-9.139300")
        guard case .found(let resolvedLocation) = sut.geocodingState else {
            return XCTFail("Expected geocodingState to be .found")
        }
        XCTAssertEqual(resolvedLocation, geocodedLocation)
    }

    func test_searchLocationByName_failure_setsFailedState() async {
        let sut = LocationsViewModel(
            repository: MockLocationsRepository(result: .success([])),
            deepLinkBuilder: MockDeepLinkBuilder(result: .failure(MockError())),
            appOpener: MockAppOpener(),
            geocoder: MockLocationGeocoder(result: .failure(LocationGeocodingError.noMatchFound))
        )
        sut.updateLocationSearchQuery("NoSuchPlace")

        let didFind = await sut.searchLocationByName()

        XCTAssertFalse(didFind)
        guard case .failed(let message) = sut.geocodingState else {
            return XCTFail("Expected geocodingState to be .failed")
        }
        XCTAssertFalse(message.isEmpty)
    }

    func test_openGeocodedLocation_success_opensResolvedURL() async {
        let geocodedLocation = LocationItem(name: "Lisbon", latitude: 38.7223, longitude: -9.1393)
        let expectedURL = URL(string: "wikipedia://places?lat=38.722300&lon=-9.139300")!
        let opener = MockAppOpener()
        let sut = LocationsViewModel(
            repository: MockLocationsRepository(result: .success([])),
            deepLinkBuilder: MockDeepLinkBuilder(result: .success(expectedURL)),
            appOpener: opener,
            geocoder: MockLocationGeocoder(result: .success(geocodedLocation))
        )
        sut.updateLocationSearchQuery("Lisbon")
        _ = await sut.searchLocationByName()

        let didOpen = await sut.openGeocodedLocation()

        XCTAssertTrue(didOpen)
        XCTAssertEqual(opener.openedURLs, [expectedURL])
    }
}

private struct MockLocationsRepository: LocationsRepository {
    let result: Result<[LocationItem], Error>

    func fetchLocations() async throws -> [LocationItem] {
        try result.get()
    }
}

private struct MockDeepLinkBuilder: WikipediaDeepLinkBuilding {
    let result: Result<URL, Error>

    func makePlacesURL(coordinate: CLLocationCoordinate2D) throws -> URL {
        try result.get()
    }
}

private struct MockLocationGeocoder: LocationGeocoding {
    let result: Result<LocationItem, Error>

    func geocodeLocation(named query: String) async throws -> LocationItem {
        try result.get()
    }
}

private final class MockAppOpener: ExternalAppOpening {
    private let error: Error?
    private(set) var openedURLs: [URL] = []

    init(error: Error? = nil) {
        self.error = error
    }

    func open(_ url: URL) async throws {
        if let error {
            throw error
        }
        openedURLs.append(url)
    }
}

private struct MockError: Error, LocalizedError {
    var errorDescription: String? {
        "Mock error"
    }
}
