import Foundation

/// Authentication Service
public class AuthenticationService {
    private let client: MojangAPIClientProtocol

    public init(client: MojangAPIClientProtocol = MojangAPIClient()) {
        self.client = client
    }

    // MARK: - Microsoft Authentication

    /// Get Microsoft OAuth Authorization URL
    /// - Parameters:
    ///   - clientId: Application ID
    ///   - redirectUri: Redirect URI
    ///   - codeChallenge: PKCE Code Challenge
    ///   - state: CSRF Protection State
    /// - Returns: Authorization URL
    public func getMicrosoftAuthorizationURL(
        clientId: String,
        redirectUri: String,
        codeChallenge: String,
        state: String
    ) -> URL? {
        var components = URLComponents(string: "https://login.microsoftonline.com/consumers/oauth2/v2.0/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "XboxLive.signin offline_access"),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: state)
        ]
        return components?.url
    }

    /// Exchange Authorization Code for Microsoft Token
    /// - Parameters:
    ///   - code: Authorization Code
    ///   - clientId: Application ID
    ///   - redirectUri: Redirect URI
    ///   - codeVerifier: PKCE Code Verifier
    /// - Returns: Token Response
    public func exchangeAuthorizationCode(
        code: String,
        clientId: String,
        redirectUri: String,
        codeVerifier: String
    ) async throws -> MicrosoftTokenResponse {
        let body = [
            "client_id": clientId,
            "code": code,
            "grant_type": "authorization_code",
            "redirect_uri": redirectUri,
            "code_verifier": codeVerifier
        ]

        var request = URLRequest(url: URL(string: "https://login.microsoftonline.com/consumers/oauth2/v2.0/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var components = URLComponents()
        components.queryItems = body.map { URLQueryItem(name: $0.key, value: $0.value) }
        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()
        return try decoder.decode(MicrosoftTokenResponse.self, from: data)
    }

    /// Refresh Microsoft Token
    /// - Parameters:
    ///   - refreshToken: Refresh Token
    ///   - clientId: Application ID
    /// - Returns: New Token Response
    public func refreshMicrosoftToken(
        refreshToken: String,
        clientId: String
    ) async throws -> MicrosoftTokenResponse {
        let body = [
            "client_id": clientId,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token",
            "scope": "XboxLive.signin offline_access"
        ]

        var request = URLRequest(url: URL(string: "https://login.live.com/oauth20_token.srf")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var components = URLComponents()
        components.queryItems = body.map { URLQueryItem(name: $0.key, value: $0.value) }
        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)

        let decoder = JSONDecoder()
        return try decoder.decode(MicrosoftTokenResponse.self, from: data)
    }

    // MARK: - Xbox Live Authentication

    /// Authenticate with Xbox Live using Microsoft Token
    /// - Parameter microsoftAccessToken: Microsoft Access Token
    /// - Returns: Xbox Live Authentication Response
    public func authenticateWithXboxLive(microsoftAccessToken: String) async throws -> XBLAuthResponse {
        let request = XBLAuthRequest(accessToken: microsoftAccessToken)
        let encoder = JSONEncoder()
        let body = try encoder.encode(request)

        var urlRequest = URLRequest(url: URL(string: "https://user.auth.xboxlive.com/user/authenticate")!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        try validateResponse(response)

        let decoder = JSONDecoder()
        return try decoder.decode(XBLAuthResponse.self, from: data)
    }

    // MARK: - XSTS Authentication

    /// Authenticate with XSTS using Xbox Live Token
    /// - Parameter xblToken: Xbox Live Token
    /// - Returns: XSTS Authentication Response
    public func authenticateWithXSTS(xblToken: String) async throws -> XSTSAuthResponse {
        let request = XSTSAuthRequest(xblToken: xblToken)
        let encoder = JSONEncoder()
        let body = try encoder.encode(request)

        var urlRequest = URLRequest(url: URL(string: "https://xsts.auth.xboxlive.com/xsts/authorize")!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        try validateResponse(response)

        let decoder = JSONDecoder()
        return try decoder.decode(XSTSAuthResponse.self, from: data)
    }

    // MARK: - Minecraft Authentication

    /// Authenticate with Minecraft using XSTS Token
    /// - Parameters:
    ///   - userHash: Xbox Live User Hash
    ///   - xstsToken: XSTS Token
    /// - Returns: Minecraft Authentication Response
    public func authenticateWithMinecraft(userHash: String, xstsToken: String) async throws -> MinecraftAuthResponse {
        let identityToken = "XBL3.0 x=\(userHash);\(xstsToken)"
        let request = MinecraftAuthRequest(identityToken: identityToken)
        let encoder = JSONEncoder()
        let body = try encoder.encode(request)

        var urlRequest = URLRequest(url: URL(string: "https://api.minecraftservices.com/authentication/login_with_xbox")!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        try validateResponse(response)

        let decoder = JSONDecoder()
        return try decoder.decode(MinecraftAuthResponse.self, from: data)
    }

    // MARK: - Mojang Authentication (Legacy)

    /// Authenticate using Mojang Credentials (Legacy)
    /// - Parameters:
    ///   - username: Username
    ///   - password: Password
    ///   - clientToken: Client Token
    /// - Returns: Mojang Authentication Response
    public func authenticateWithMojang(
        username: String,
        password: String,
        clientToken: String
    ) async throws -> MojangAuthResponse {
        let request = MojangAuthRequest(username: username, password: password, clientToken: clientToken)
        let encoder = JSONEncoder()
        let body = try encoder.encode(request)

        var urlRequest = URLRequest(url: URL(string: "https://authserver.mojang.com/authenticate")!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        try validateResponse(response)

        let decoder = JSONDecoder()
        return try decoder.decode(MojangAuthResponse.self, from: data)
    }

    // MARK: - Private Methods

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MojangAPIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw MojangAPIError.unauthorized
        case 403:
            throw MojangAPIError.unauthorized
        case 429:
            throw MojangAPIError.rateLimited
        default:
            throw MojangAPIError.httpError(
                statusCode: httpResponse.statusCode,
                message: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            )
        }
    }
}
