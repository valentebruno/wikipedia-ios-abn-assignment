import Foundation

protocol LocationsRepository {
    func fetchLocations() async throws -> [LocationItem]
}

typealias LocationsFetching = LocationsRepository

enum LocationsRepositoryError: Error, Equatable {
    case invalidResponse(URL)
    case httpStatus(Int, URL)
    case decodingFailure(URL)
    case emptyLocations(URL)
}

extension LocationsRepositoryError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The locations service returned an invalid response."
        case .httpStatus(let statusCode, _):
            return "The locations service returned HTTP \(statusCode)."
        case .decodingFailure:
            return "Could not decode locations from the service response."
        case .emptyLocations:
            return "The service returned no locations."
        }
    }
}

actor RemoteLocationsRepository: LocationsRepository {
    static let assignmentURL = URL(string: "https://raw.githubusercontent.com/abnamrocoesd/assignment-ios/main/locations.json")!

    private static var defaultSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let endpoint: URL

    init(
        session: URLSession? = nil,
        decoder: JSONDecoder = JSONDecoder(),
        endpoint: URL = assignmentURL
    ) {
        self.session = session ?? RemoteLocationsRepository.defaultSession
        self.decoder = decoder
        self.endpoint = endpoint
    }

    func fetchLocations() async throws -> [LocationItem] {
        try await fetchLocations(at: endpoint)
    }

    private func fetchLocations(at endpoint: URL) async throws -> [LocationItem] {
        let (data, response) = try await session.data(from: endpoint)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LocationsRepositoryError.invalidResponse(endpoint)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw LocationsRepositoryError.httpStatus(httpResponse.statusCode, endpoint)
        }

        let payload: LocationsResponse
        do {
            payload = try decoder.decode(LocationsResponse.self, from: data)
        } catch {
            throw LocationsRepositoryError.decodingFailure(endpoint)
        }

        guard !payload.locations.isEmpty else {
            throw LocationsRepositoryError.emptyLocations(endpoint)
        }
        return payload.locations
    }
}
