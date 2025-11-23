import Foundation

/// Mojang API Error Types
public enum MojangAPIError: LocalizedError {
    /// Network Error
    case networkError(URLError)
    /// HTTP Error
    case httpError(statusCode: Int, message: String)
    /// Decoding Error
    case decodingError(DecodingError)
    /// Error Returned by Mojang API
    case apiError(error: String, errorMessage: String, cause: String?)
    /// Invalid URL
    case invalidURL
    /// Invalid Response
    case invalidResponse
    /// Token Expired
    case tokenExpired
    /// Unauthorized
    case unauthorized
    /// Not Found
    case notFound
    /// Rate Limited
    case rateLimited
    /// Unknown Error
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network Error: \(error.localizedDescription)"
        case .httpError(let statusCode, let message):
            return "HTTP \(statusCode): \(message)"
        case .decodingError(let error):
            return "Decoding Error: \(error.localizedDescription)"
        case .apiError(let error, let message, let cause):
            var description = "\(error): \(message)"
            if let cause = cause {
                description += " (\(cause))"
            }
            return description
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid Response"
        case .tokenExpired:
            return "Token Expired"
        case .unauthorized:
            return "Unauthorized"
        case .notFound:
            return "Not Found"
        case .rateLimited:
            return "Request Too Frequent, Please Try Again Later"
        case .unknown(let message):
            return message
        }
    }

    public var failureReason: String? {
        switch self {
        case .networkError:
            return "Unable to Connect to Mojang Server"
        case .httpError:
            return "Server Returned Error"
        case .decodingError:
            return "Unable to Parse Server Response"
        case .apiError:
            return "Mojang API Returned Error"
        case .tokenExpired:
            return "Authentication Token Expired, Please Log In Again"
        case .unauthorized:
            return "Authentication Failed, Please Check Credentials"
        case .rateLimited:
            return "Request Too Frequent"
        default:
            return nil
        }
    }
}

/// Mojang API Error Response Model
struct MojangAPIErrorResponse: Decodable {
    let error: String
    let errorMessage: String
    let cause: String?

    enum CodingKeys: String, CodingKey {
        case error
        case errorMessage
        case cause
    }
}
