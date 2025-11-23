//
//  AuthenticationService.swift
//  MojangAPI
//

import Foundation

/// Authentication Service
public class AuthenticationService {
  private let client: MojangAPIClientProtocol

  public init(client: MojangAPIClientProtocol = MojangAPIClient()) {
    self.client = client
  }

  // MARK: - Authorization Code Parsing

  /// Parses authorization code from callback URL
  /// - Parameters:
  ///   - urlString: The callback URL string
  ///   - expectedState: The expected state value for CSRF protection
  /// - Returns: The authorization code
  /// - Throws: MojangAPIError if parsing fails or state doesn't match
  public func parseAuthorizationCodeURL(
    _ urlString: String,
    expectedState: String
  ) throws -> String {
    guard let url = URL(string: urlString),
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    else {
      throw MojangAPIError.invalidResponse
    }

    // Check state to prevent CSRF attacks
    if let stateItem = components.queryItems?.first(where: {
      $0.name == "state"
    }),
      let state = stateItem.value
    {
      guard state == expectedState else {
        throw MojangAPIError.unauthorized
      }
    }

    // Get authorization code
    guard
      let codeItem = components.queryItems?.first(where: { $0.name == "code" }),
      let code = codeItem.value
    else {
      throw MojangAPIError.invalidResponse
    }

    return code
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
    var components = URLComponents(
      string:
        "https://login.microsoftonline.com/consumers/oauth2/v2.0/authorize"
    )
    components?.queryItems = [
      URLQueryItem(name: "client_id", value: clientId),
      URLQueryItem(name: "response_type", value: "code"),
      URLQueryItem(name: "scope", value: "XboxLive.signin offline_access"),
      URLQueryItem(name: "redirect_uri", value: redirectUri),
      URLQueryItem(name: "code_challenge", value: codeChallenge),
      URLQueryItem(name: "code_challenge_method", value: "S256"),
      URLQueryItem(name: "state", value: state),
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
      "code_verifier": codeVerifier,
    ]

    var request = URLRequest(
      url: URL(
        string: "https://login.microsoftonline.com/consumers/oauth2/v2.0/token"
      )!
    )
    request.httpMethod = "POST"
    request.setValue(
      "application/x-www-form-urlencoded",
      forHTTPHeaderField: "Content-Type"
    )

    // Properly encode form data
    let encodedBody =
      body
      .map {
        "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
      }
      .joined(separator: "&")
    request.httpBody = encodedBody.data(using: .utf8)

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
      "scope": "XboxLive.signin offline_access",
      "refresh_token": refreshToken,
      "grant_type": "refresh_token",
    ]

    var request = URLRequest(
      url: URL(string: "https://login.live.com/oauth20_token.srf")!
    )
    request.httpMethod = "POST"
    request.setValue(
      "application/x-www-form-urlencoded",
      forHTTPHeaderField: "Content-Type"
    )

    // Properly encode form data
    let encodedBody =
      body
      .map {
        "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
      }
      .joined(separator: "&")
    request.httpBody = encodedBody.data(using: .utf8)

    let (data, response) = try await URLSession.shared.data(for: request)
    try validateResponse(response)

    let decoder = JSONDecoder()
    return try decoder.decode(MicrosoftTokenResponse.self, from: data)
  }

  // MARK: - Xbox Live Authentication

  /// Authenticate with Xbox Live using Microsoft Token
  /// - Parameter microsoftAccessToken: Microsoft Access Token
  /// - Returns: Xbox Live Authentication Response
  public func authenticateWithXboxLive(microsoftAccessToken: String)
    async throws -> XBLAuthResponse
  {
    let request = XBLAuthRequest(accessToken: microsoftAccessToken)
    let encoder = JSONEncoder()
    let body = try encoder.encode(request)

    var urlRequest = URLRequest(
      url: URL(string: "https://user.auth.xboxlive.com/user/authenticate")!
    )
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
  public func authenticateWithXSTS(xblToken: String) async throws
    -> XSTSAuthResponse
  {
    let request = XSTSAuthRequest(xblToken: xblToken)
    let encoder = JSONEncoder()
    let body = try encoder.encode(request)

    var urlRequest = URLRequest(
      url: URL(string: "https://xsts.auth.xboxlive.com/xsts/authorize")!
    )
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
  public func authenticateWithMinecraft(userHash: String, xstsToken: String)
    async throws -> MinecraftAuthResponse
  {
    let identityToken = "XBL3.0 x=\(userHash);\(xstsToken)"
    let request = MinecraftAuthRequest(identityToken: identityToken)
    let encoder = JSONEncoder()
    let body = try encoder.encode(request)

    var urlRequest = URLRequest(
      url: URL(
        string:
          "https://api.minecraftservices.com/authentication/login_with_xbox"
      )!
    )
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
    let request = MojangAuthRequest(
      username: username,
      password: password,
      clientToken: clientToken
    )
    let encoder = JSONEncoder()
    let body = try encoder.encode(request)

    var urlRequest = URLRequest(
      url: URL(string: "https://authserver.mojang.com/authenticate")!
    )
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.httpBody = body

    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    try validateResponse(response)

    let decoder = JSONDecoder()
    return try decoder.decode(MojangAuthResponse.self, from: data)
  }

  // MARK: - Minecraft Profile

  /// Gets Minecraft profile using Minecraft access token
  /// - Parameter accessToken: Minecraft access token
  /// - Returns: Profile information with skins and capes
  public func getMinecraftProfile(accessToken: String) async throws -> (
    id: String, name: String, skins: [SkinInfo]?, capes: [CapeInfo]?
  ) {
    guard
      let url = URL(
        string: "https://api.minecraftservices.com/minecraft/profile"
      )
    else {
      throw MojangAPIError.invalidResponse
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue(
      "Bearer \(accessToken)",
      forHTTPHeaderField: "Authorization"
    )

    let (data, response) = try await URLSession.shared.data(for: request)
    try validateResponse(response)

    let decoder = JSONDecoder()
    let profileResponse: MinecraftProfileResponse = try decoder.decode(
      MinecraftProfileResponse.self,
      from: data
    )

    return (
      id: profileResponse.id,
      name: profileResponse.name,
      skins: profileResponse.skins,
      capes: profileResponse.capes
    )
  }

  // MARK: - Complete Authentication Flows

  /// Completes the entire Microsoft login flow from authorization code to profile
  /// - Parameters:
  ///   - authCode: Authorization code from callback
  ///   - codeVerifier: PKCE code verifier
  ///   - clientId: Microsoft application ID
  ///   - redirectUri: Redirect URI
  /// - Returns: Complete login response with profile and tokens
  public func completeLogin(
    authCode: String,
    codeVerifier: String,
    clientId: String,
    redirectUri: String
  ) async throws -> CompleteLoginResponse {
    // Step 1: Exchange authorization code for Microsoft token
    let tokenResponse = try await exchangeAuthorizationCode(
      code: authCode,
      clientId: clientId,
      redirectUri: redirectUri,
      codeVerifier: codeVerifier
    )

    // Step 2: Authenticate with Xbox Live
    let xblResponse = try await authenticateWithXboxLive(
      microsoftAccessToken: tokenResponse.accessToken
    )
    let xblToken = xblResponse.token
    let userHash = xblResponse.displayClaims.xui[0].uhs

    // Step 3: Authenticate with XSTS
    let xstsResponse = try await authenticateWithXSTS(xblToken: xblToken)
    let xstsToken = xstsResponse.token

    // Step 4: Authenticate with Minecraft
    let minecraftAuth = try await authenticateWithMinecraft(
      userHash: userHash,
      xstsToken: xstsToken
    )

    // Verify access token is present
    guard !minecraftAuth.accessToken.isEmpty else {
      throw MojangAPIError.unauthorized
    }

    // Step 5: Get Minecraft profile
    let profile = try await getMinecraftProfile(
      accessToken: minecraftAuth.accessToken
    )

    return CompleteLoginResponse(
      id: profile.id,
      name: profile.name,
      accessToken: minecraftAuth.accessToken,
      refreshToken: tokenResponse.refreshToken ?? "",
      skins: profile.skins,
      capes: profile.capes
    )
  }

  /// Completes the refresh flow to get new access token and profile
  /// - Parameters:
  ///   - refreshToken: Refresh token from previous login
  ///   - clientId: Microsoft application ID
  /// - Returns: Complete login response with updated tokens and profile
  public func completeRefresh(
    refreshToken: String,
    clientId: String
  ) async throws -> CompleteLoginResponse {
    // Step 1: Refresh Microsoft token
    let tokenResponse = try await refreshMicrosoftToken(
      refreshToken: refreshToken,
      clientId: clientId
    )

    // Step 2: Authenticate with Xbox Live
    let xblResponse = try await authenticateWithXboxLive(
      microsoftAccessToken: tokenResponse.accessToken
    )
    let xblToken = xblResponse.token
    let userHash = xblResponse.displayClaims.xui[0].uhs

    // Step 3: Authenticate with XSTS
    let xstsResponse = try await authenticateWithXSTS(xblToken: xblToken)
    let xstsToken = xstsResponse.token

    // Step 4: Authenticate with Minecraft
    let minecraftAuth = try await authenticateWithMinecraft(
      userHash: userHash,
      xstsToken: xstsToken
    )

    // Step 5: Get Minecraft profile
    let profile = try await getMinecraftProfile(
      accessToken: minecraftAuth.accessToken
    )

    return CompleteLoginResponse(
      id: profile.id,
      name: profile.name,
      accessToken: minecraftAuth.accessToken,
      refreshToken: tokenResponse.refreshToken ?? "",
      skins: profile.skins,
      capes: profile.capes
    )
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
        message: HTTPURLResponse.localizedString(
          forStatusCode: httpResponse.statusCode
        )
      )
    }
  }
}
