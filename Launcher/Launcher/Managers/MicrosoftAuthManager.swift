//
//  MicrosoftAuthManager.swift
//  Launcher
//
//  Microsoft Account Authentication Manager
//  Implements OAuth 2.0 + Xbox Live + Minecraft Services authentication flow
//

import Foundation
import MojangAPI

// MARK: - Secure Login Data

struct SecureLoginData {
  let url: String
  let state: String
  let codeVerifier: String
}

// MARK: - Microsoft Authentication Manager

class MicrosoftAuthManager: MicrosoftAuthProtocol {
  // swiftlint:disable:previous type_body_length

  static let shared = MicrosoftAuthManager(configuration: .fromBundleOrFatal())

  // Authentication Configuration
  private let configuration: AuthConfiguration

  private var clientID: String { configuration.clientID }
  private var redirectURI: String { configuration.redirectURI }
  private var scope: String { configuration.scope }

  init(configuration: AuthConfiguration) {
    self.configuration = configuration
  }

  // MARK: - Step 1: Generate Secure Login Data

  /// Generates secure login data with PKCE and state for authentication
  func getSecureLoginData() -> SecureLoginData {
    let state = PKCEHelper.generateState()
    let codePair = PKCEHelper.generateCodePair()

    let endpoint = MojangEndpoint.microsoftOAuthAuthorize
    let url = try! endpoint.buildURL()
    guard var components = URLComponents(string: url.absoluteString) else {
      fatalError("Invalid Microsoft Auth URL configuration")
    }
    components.queryItems = [
      URLQueryItem(name: "client_id", value: clientID),
      URLQueryItem(name: "response_type", value: "code"),
      URLQueryItem(name: "redirect_uri", value: redirectURI),
      URLQueryItem(name: "response_mode", value: "query"),
      URLQueryItem(name: "scope", value: scope),
      URLQueryItem(name: "state", value: state),
      URLQueryItem(name: "code_challenge", value: codePair.challenge),
      URLQueryItem(name: "code_challenge_method", value: "S256"),
    ]

    guard let url = components.url else {
      fatalError("Failed to construct authorization URL")
    }

    return SecureLoginData(
      url: url.absoluteString,
      state: state,
      codeVerifier: codePair.verifier
    )
  }

  // MARK: - Step 2: Parse Authorization Code from URL

  /// Parses authorization code from callback URL
  func parseAuthCodeURL(_ urlString: String, expectedState: String) throws -> String {
    guard let url = URL(string: urlString),
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    else {
      throw MicrosoftAuthError.invalidURL
    }

    // Check state to prevent CSRF attacks
    if let stateItem = components.queryItems?.first(where: { $0.name == "state" }),
      let state = stateItem.value
    {
      guard state == expectedState else {
        throw MicrosoftAuthError.stateMismatch
      }
    }

    // Get authorization code
    guard let codeItem = components.queryItems?.first(where: { $0.name == "code" }),
      let code = codeItem.value
    else {
      throw MicrosoftAuthError.authCodeNotFound
    }

    return code
  }

  // MARK: - Step 3: Get Authorization Token

  /// Exchanges authorization code for access token and refresh token
  func getAuthorizationToken(authCode: String, codeVerifier: String) async throws
    -> AuthorizationTokenResponse
  {
    guard let url = URL(string: APIService.MicrosoftAuth.token) else {
      throw MicrosoftAuthError.invalidURL
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

    let parameters = [
      "client_id": clientID,
      "scope": scope,
      "code": authCode,
      "redirect_uri": redirectURI,
      "grant_type": "authorization_code",
      "code_verifier": codeVerifier,
    ]

    request.httpBody =
      parameters
      .map {
        "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
      }
      .joined(separator: "&")
      .data(using: .utf8)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
      (200...299).contains(httpResponse.statusCode)
    else {
      throw MicrosoftAuthError.httpError
    }

    return try JSONDecoder().decode(AuthorizationTokenResponse.self, from: data)
  }

  // MARK: - Step 4: Authenticate with Xbox Live

  /// Authenticates with Xbox Live using Microsoft access token
  func authenticateWithXBL(accessToken: String) async throws -> XBLResponse {
    guard let url = URL(string: APIService.XboxLive.authenticate) else {
      throw MicrosoftAuthError.invalidURL
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    let body: [String: Any] = [
      "Properties": [
        "AuthMethod": "RPS",
        "SiteName": "user.auth.xboxlive.com",
        "RpsTicket": "d=\(accessToken)",
      ],
      "RelyingParty": APIService.XboxLive.relyingParty,
      "TokenType": "JWT",
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
      (200...299).contains(httpResponse.statusCode)
    else {
      throw MicrosoftAuthError.xblAuthFailed
    }

    return try JSONDecoder().decode(XBLResponse.self, from: data)
  }

  // MARK: - Step 5: Authenticate with XSTS

  /// Authenticates with XSTS using XBL token
  func authenticateWithXSTS(xblToken: String) async throws -> XBLResponse {
    guard let url = URL(string: APIService.XboxLive.authorize) else {
      throw MicrosoftAuthError.invalidURL
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    let body: [String: Any] = [
      "Properties": [
        "SandboxId": "RETAIL",
        "UserTokens": [xblToken],
      ],
      "RelyingParty": APIService.MinecraftServices.relyingParty,
      "TokenType": "JWT",
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
      (200...299).contains(httpResponse.statusCode)
    else {
      throw MicrosoftAuthError.xstsAuthFailed
    }

    return try JSONDecoder().decode(XBLResponse.self, from: data)
  }

  // MARK: - Step 6: Authenticate with Minecraft

  /// Authenticates with Minecraft using XSTS token
  func authenticateWithMinecraft(userHash: String, xstsToken: String) async throws
    -> MinecraftAuthResponse
  {
    guard let url = URL(string: APIService.MinecraftServices.loginWithXbox) else {
      throw MicrosoftAuthError.invalidURL
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    let body: [String: String] = [
      "identityToken": "XBL3.0 x=\(userHash);\(xstsToken)"
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
      (200...299).contains(httpResponse.statusCode)
    else {
      throw MicrosoftAuthError.minecraftAuthFailed
    }

    return try JSONDecoder().decode(MinecraftAuthResponse.self, from: data)
  }

  // MARK: - Step 7: Get Minecraft Profile

  /// Gets Minecraft profile using Minecraft access token
  func getProfile(accessToken: String) async throws -> MinecraftProfileResponse {
    guard let url = URL(string: APIService.MinecraftServices.profile) else {
      throw MicrosoftAuthError.invalidURL
    }
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
      (200...299).contains(httpResponse.statusCode)
    else {
      throw MicrosoftAuthError.profileFetchFailed
    }

    return try JSONDecoder().decode(MinecraftProfileResponse.self, from: data)
  }

  // MARK: - Complete Login Flow

  /// Completes the entire login flow from authorization code to profile
  func completeLogin(authCode: String, codeVerifier: String) async throws -> CompleteLoginResponse {
    // Step 3: Get authorization token
    let tokenResponse = try await getAuthorizationToken(
      authCode: authCode, codeVerifier: codeVerifier)

    // Step 4: Authenticate with XBL
    let xblResponse = try await authenticateWithXBL(accessToken: tokenResponse.accessToken)
    let xblToken = xblResponse.token
    let userHash = xblResponse.displayClaims.xui[0].uhs

    // Step 5: Authenticate with XSTS
    let xstsResponse = try await authenticateWithXSTS(xblToken: xblToken)
    let xstsToken = xstsResponse.token

    // Step 6: Authenticate with Minecraft
    let minecraftAuth = try await authenticateWithMinecraft(
      userHash: userHash, xstsToken: xstsToken)

    // Check if access token is present (indicates success)
    guard !minecraftAuth.accessToken.isEmpty else {
      throw MicrosoftAuthError.azureAppNotPermitted
    }

    // Step 7: Get Minecraft profile
    let profile = try await getProfile(accessToken: minecraftAuth.accessToken)

    return buildCompleteLoginResponse(
      profile: profile,
      accessToken: minecraftAuth.accessToken,
      refreshToken: tokenResponse.refreshToken
    )
  }

  // MARK: - Refresh Token Flow

  /// Refreshes authentication using refresh token
  func refreshAuthorizationToken(refreshToken: String) async throws -> AuthorizationTokenResponse {
    guard let url = URL(string: APIService.MicrosoftAuth.refreshToken) else {
      throw MicrosoftAuthError.invalidURL
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

    let parameters = [
      "client_id": clientID,
      "scope": scope,
      "refresh_token": refreshToken,
      "grant_type": "refresh_token",
    ]

    request.httpBody =
      parameters
      .map {
        "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
      }
      .joined(separator: "&")
      .data(using: .utf8)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
      (200...299).contains(httpResponse.statusCode)
    else {
      throw MicrosoftAuthError.invalidRefreshToken
    }

    return try JSONDecoder().decode(AuthorizationTokenResponse.self, from: data)
  }

  /// Completes refresh flow to get new access token and profile
  func completeRefresh(refreshToken: String) async throws -> CompleteLoginResponse {
    // Refresh authorization token
    let tokenResponse = try await refreshAuthorizationToken(refreshToken: refreshToken)

    // Follow steps 4-7
    let xblResponse = try await authenticateWithXBL(accessToken: tokenResponse.accessToken)
    let xblToken = xblResponse.token
    let userHash = xblResponse.displayClaims.xui[0].uhs

    let xstsResponse = try await authenticateWithXSTS(xblToken: xblToken)
    let xstsToken = xstsResponse.token

    let minecraftAuth = try await authenticateWithMinecraft(
      userHash: userHash, xstsToken: xstsToken)
    let profile = try await getProfile(accessToken: minecraftAuth.accessToken)

    return buildCompleteLoginResponse(
      profile: profile,
      accessToken: minecraftAuth.accessToken,
      refreshToken: tokenResponse.refreshToken
    )
  }

  // MARK: - Helper Functions

  /// Converts MinecraftProfileResponse to CompleteLoginResponse
  private func buildCompleteLoginResponse(
    profile: MinecraftProfileResponse,
    accessToken: String,
    refreshToken: String
  ) -> CompleteLoginResponse {
    let skins = profile.skins?.map { skin in
      SkinInfo(
        id: skin.id,
        url: skin.url,
        state: skin.state,
        variant: skin.variant,
        alias: skin.alias
      )
    }

    let capes = profile.capes?.map { cape in
      CapeInfo(
        id: cape.id,
        url: cape.url,
        state: cape.state,
        alias: cape.alias
      )
    }

    return CompleteLoginResponse(
      id: profile.id,
      name: profile.name,
      accessToken: accessToken,
      refreshToken: refreshToken,
      skins: skins,
      capes: capes
    )
  }
}

// MARK: - Error Types

enum MicrosoftAuthError: LocalizedError {
  case invalidURL
  case stateMismatch
  case authCodeNotFound
  case httpError
  case xblAuthFailed
  case xstsAuthFailed
  case minecraftAuthFailed
  case profileFetchFailed
  case azureAppNotPermitted
  case accountNotOwnMinecraft
  case invalidRefreshToken

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid URL"
    case .stateMismatch:
      return "State mismatch - possible CSRF attack"
    case .authCodeNotFound:
      return "Authorization code not found in callback URL"
    case .httpError:
      return "HTTP error occurred"
    case .xblAuthFailed:
      return "Xbox Live authentication failed"
    case .xstsAuthFailed:
      return "XSTS authentication failed"
    case .minecraftAuthFailed:
      return "Minecraft authentication failed"
    case .profileFetchFailed:
      return "Failed to fetch Minecraft profile"
    case .azureAppNotPermitted:
      return "Azure application not permitted to access Minecraft API"
    case .accountNotOwnMinecraft:
      return "Account does not own Minecraft"
    case .invalidRefreshToken:
      return "Invalid or expired refresh token"
    }
  }
}
