import Foundation

/// Mojang API Client Protocol
public protocol MojangAPIClientProtocol {
    func request<T: Decodable>(_ endpoint: MojangEndpoint, body: Encodable?) async throws -> T
    func request(_ endpoint: MojangEndpoint, body: Encodable?) async throws -> Data
}

// MARK: - Default Implementation Extension
extension MojangAPIClientProtocol {
    func request<T: Decodable>(_ endpoint: MojangEndpoint) async throws -> T {
        try await request(endpoint, body: nil)
    }

    func request(_ endpoint: MojangEndpoint) async throws -> Data {
        try await request(endpoint, body: nil)
    }
}

/// Mojang API Client Implementation
public class MojangAPIClient: MojangAPIClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    // MARK: - Public Methods

    /// Send request and decode response
    public func request<T: Decodable>(_ endpoint: MojangEndpoint, body: Encodable? = nil) async throws -> T {
        let data = try await request(endpoint, body: body)
        do {
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            throw MojangAPIError.decodingError(error)
        }
    }

    /// Send request and return raw data
    public func request(_ endpoint: MojangEndpoint, body: Encodable? = nil) async throws -> Data {
        let url = try endpoint.buildURL()
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            request.httpBody = try encoder.encode(body)
        }

        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response, data: data)
            return data
        } catch let error as URLError {
            throw MojangAPIError.networkError(error)
        } catch let error as MojangAPIError {
            throw error
        } catch {
            throw MojangAPIError.unknown(error.localizedDescription)
        }
    }

    // MARK: - Private Methods

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MojangAPIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 400:
            try handleErrorResponse(data)
        case 401:
            throw MojangAPIError.unauthorized
        case 403:
            throw MojangAPIError.unauthorized
        case 404:
            throw MojangAPIError.notFound
        case 429:
            throw MojangAPIError.rateLimited
        default:
            throw MojangAPIError.httpError(
                statusCode: httpResponse.statusCode,
                message: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            )
        }
    }

    private func handleErrorResponse(_ data: Data) throws {
        do {
            let errorResponse = try decoder.decode(MojangAPIErrorResponse.self, from: data)
            throw MojangAPIError.apiError(
                error: errorResponse.error,
                errorMessage: errorResponse.errorMessage,
                cause: errorResponse.cause
            )
        } catch let error as MojangAPIError {
            throw error
        } catch {
            throw MojangAPIError.unknown("Unable to parse error response")
        }
    }
}
