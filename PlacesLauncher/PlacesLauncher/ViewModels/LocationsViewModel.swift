import CoreLocation
import Foundation

@MainActor
final class LocationsViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    enum GeocodingState: Equatable {
        case idle
        case searching
        case found(LocationItem)
        case failed(String)
    }

    @Published private(set) var loadState: LoadState = .idle
    @Published private(set) var locations: [LocationItem] = []
    @Published var alertMessage: String?
    @Published var customLatitude: String = ""
    @Published var customLongitude: String = ""
    @Published private(set) var geocodingState: GeocodingState = .idle
    @Published private(set) var locationSearchQuery: String = ""

    private let repository: any LocationsRepository
    private let deepLinkBuilder: any WikipediaDeepLinkBuilding
    private let appOpener: any ExternalAppOpening
    private let coordinateParser: any CoordinateParsing
    private let geocoder: any LocationGeocoding

    init(
        repository: any LocationsRepository = RemoteLocationsRepository(),
        deepLinkBuilder: any WikipediaDeepLinkBuilding = WikipediaDeepLinkBuilder(),
        appOpener: any ExternalAppOpening = UIApplicationExternalAppOpener(),
        coordinateParser: any CoordinateParsing = CoordinateParser(),
        geocoder: any LocationGeocoding = CLGeocoderLocationGeocoder()
    ) {
        self.repository = repository
        self.deepLinkBuilder = deepLinkBuilder
        self.appOpener = appOpener
        self.coordinateParser = coordinateParser
        self.geocoder = geocoder
    }

    func loadIfNeeded() async {
        guard loadState == .idle else {
            return
        }
        await loadLocations()
    }

    func loadLocations() async {
        loadState = .loading
        do {
            locations = try await repository.fetchLocations()
            loadState = .loaded
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    @discardableResult
    func openWikipedia(for location: LocationItem) async -> Bool {
        await openWikipedia(at: location.coordinate)
    }

    @discardableResult
    func openCustomCoordinate() async -> Bool {
        guard let coordinate = coordinateParser.parse(latitudeText: customLatitude, longitudeText: customLongitude) else {
            alertMessage = WikipediaDeepLinkError.invalidCoordinate.localizedDescription
            return false
        }
        return await openWikipedia(at: coordinate)
    }

    func dismissAlert() {
        alertMessage = nil
    }

    func updateLocationSearchQuery(_ query: String) {
        locationSearchQuery = query
        geocodingState = .idle
    }

    @discardableResult
    func searchLocationByName() async -> Bool {
        geocodingState = .searching
        do {
            let geocodedLocation = try await geocoder.geocodeLocation(named: locationSearchQuery)
            geocodingState = .found(geocodedLocation)
            customLatitude = formattedCoordinateValue(geocodedLocation.latitude)
            customLongitude = formattedCoordinateValue(geocodedLocation.longitude)
            return true
        } catch {
            geocodingState = .failed(error.localizedDescription)
            return false
        }
    }

    @discardableResult
    func openGeocodedLocation() async -> Bool {
        guard case .found(let location) = geocodingState else {
            return false
        }
        return await openWikipedia(for: location)
    }

    private func openWikipedia(at coordinate: CLLocationCoordinate2D) async -> Bool {
        do {
            let url = try deepLinkBuilder.makePlacesURL(coordinate: coordinate)
            try await appOpener.open(url)
            return true
        } catch {
            alertMessage = error.localizedDescription
            return false
        }
    }

    private func formattedCoordinateValue(_ value: Double) -> String {
        String(format: "%.6f", value)
    }
}
