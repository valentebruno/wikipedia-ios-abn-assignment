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
    case noReachableEndpoint([URL])
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
        case .noReachableEndpoint:
            return "Could not reach any configured locations endpoint."
        }
    }
}

actor RemoteLocationsRepository: LocationsRepository {
    static let assignmentPrimaryURL = URL(string: "https://raw.githubusercontent.com/abnamrocoesd/assignment-ios/main/locations.json")!
    static let assignmentFallbackURL = URL(string: "https://raw.githubusercontent.com/abnamrocoesd/assignmentios/main/locations.json")!

    private let session: URLSession
    private let decoder: JSONDecoder
    private let endpoints: [URL]

    init(
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        endpoints: [URL] = [assignmentPrimaryURL, assignmentFallbackURL]
    ) {
        self.session = session
        self.decoder = decoder
        self.endpoints = endpoints
    }

    func fetchLocations() async throws -> [LocationItem] {
        var lastError: Error?
        for endpoint in endpoints {
            do {
                return try await fetchLocations(at: endpoint)
            } catch {
                lastError = error
            }
        }

        if let lastError {
            throw lastError
        }
        throw LocationsRepositoryError.noReachableEndpoint(endpoints)
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
