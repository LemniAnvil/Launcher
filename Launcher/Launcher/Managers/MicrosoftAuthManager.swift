//
//  MicrosoftAuthManager.swift
//  Launcher
//
//  Microsoft Account Authentication Manager
//  Implements OAuth 2.0 + Xbox Live + Minecraft Services authentication flow
//

import Foundation
import CryptoKit

// MARK: - Response Models

struct AuthorizationTokenResponse: Codable {
  let accessToken: String
  let tokenType: String
  let expiresIn: Int
  let scope: String
  let refreshToken: String

  enum CodingKeys: String, CodingKey {
    case accessToken = "access_token"
    case tokenType = "token_type"
    case expiresIn = "expires_in"
    case scope
    case refreshToken = "refresh_token"
  }
}

struct XBLResponse: Codable {
  let issueInstant: String
  let notAfter: String
  let token: String
  let displayClaims: DisplayClaims

  struct DisplayClaims: Codable {
    let xui: [UserInfo]
  }

  struct UserInfo: Codable {
    let uhs: String
  }

  enum CodingKeys: String, CodingKey {
    case issueInstant = "IssueInstant"
    case notAfter = "NotAfter"
    case token = "Token"
    case displayClaims = "DisplayClaims"
  }
}

struct MinecraftAuthResponse: Codable {
  let username: String?
  let roles: [String]?
  let accessToken: String
  let tokenType: String
  let expiresIn: Int

  enum CodingKeys: String, CodingKey {
    case username
    case roles
    case accessToken = "access_token"
    case tokenType = "token_type"
    case expiresIn = "expires_in"
  }
}

struct MinecraftProfileResponse: Codable {
  let id: String
  let name: String
  let skins: [Skin]?
  let capes: [Cape]?

  struct Skin: Codable {
    let id: String
    let state: String
    let url: String
    let variant: String
    let alias: String?
  }

  struct Cape: Codable {
    let id: String
    let state: String
    let url: String
    let alias: String?
  }
}

struct CompleteLoginResponse: Codable {
  let id: String
  let name: String
  let accessToken: String
  let refreshToken: String
  let skins: [MinecraftProfileResponse.Skin]?
  let capes: [MinecraftProfileResponse.Cape]?
}

// MARK: - Secure Login Data

struct SecureLoginData {
  let url: String
  let state: String
  let codeVerifier: String
}

// MARK: - Microsoft Authentication Manager

class MicrosoftAuthManager: MicrosoftAuthProtocol {
  // swiftlint:disable:previous type_body_length

  static let shared = MicrosoftAuthManager()

  // Azure Application Configuration
  // Loaded from Info.plist, which gets the value from Config.xcconfig
  private let clientID: String = {
    guard let id = Bundle.main.infoDictionary?["MicrosoftClientID"] as? String,
          !id.isEmpty,
          !id.contains("YOUR_"),
          !id.contains("00000000-0000-0000-0000-000000000000") else {
      fatalError("""
        ❌ Microsoft Client ID not configured!

        Please follow these steps:
        1. Ensure Config.xcconfig exists and contains MICROSOFT_CLIENT_ID
        2. Replace YOUR_MICROSOFT_CLIENT_ID_HERE with your actual client ID
        3. Configure the xcconfig file in Xcode project settings
        4. Clean build folder (⌘⇧K) and rebuild

        Get your client ID from: https://portal.azure.com/
        """)
    }
    return id
  }()

  private let redirectURI = "LemniAnvil-launcher://auth"
  private let scope = "XboxLive.signin offline_access"

  private init() {}

  // MARK: - Step 1: Generate Secure Login Data

  /// Generates secure login data with PKCE and state for authentication
  func getSecureLoginData() -> SecureLoginData {
    let state = generateState()
    let codeVerifier = generateCodeVerifier()
    let codeChallenge = generateCodeChallenge(from: codeVerifier)

    guard var components = URLComponents(string: APIService.MicrosoftAuth.authorize) else {
      fatalError("Invalid Microsoft Auth URL configuration")
    }
    components.queryItems = [
      URLQueryItem(name: "client_id", value: clientID),
      URLQueryItem(name: "response_type", value: "code"),
      URLQueryItem(name: "redirect_uri", value: redirectURI),
      URLQueryItem(name: "response_mode", value: "query"),
      URLQueryItem(name: "scope", value: scope),
      URLQueryItem(name: "state", value: state),
      URLQueryItem(name: "code_challenge", value: codeChallenge),
      URLQueryItem(name: "code_challenge_method", value: "S256"),
    ]

    guard let url = components.url else {
      fatalError("Failed to construct authorization URL")
    }

    return SecureLoginData(
      url: url.absoluteString,
      state: state,
      codeVerifier: codeVerifier
    )
  }

  // MARK: - Step 2: Parse Authorization Code from URL

  /// Parses authorization code from callback URL
  func parseAuthCodeURL(_ urlString: String, expectedState: String) throws -> String {
    guard let url = URL(string: urlString),
          let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      throw MicrosoftAuthError.invalidURL
    }

    // Check state to prevent CSRF attacks
    if let stateItem = components.queryItems?.first(where: { $0.name == "state" }),
       let state = stateItem.value {
      guard state == expectedState else {
        throw MicrosoftAuthError.stateMismatch
      }
    }

    // Get authorization code
    guard let codeItem = components.queryItems?.first(where: { $0.name == "code" }),
          let code = codeItem.value else {
      throw MicrosoftAuthError.authCodeNotFound
    }

    return code
  }

  // MARK: - Step 3: Get Authorization Token

  /// Exchanges authorization code for access token and refresh token
  func getAuthorizationToken(authCode: String, codeVerifier: String) async throws -> AuthorizationTokenResponse {
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

    request.httpBody = parameters
      .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
      .joined(separator: "&")
      .data(using: .utf8)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
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
          (200...299).contains(httpResponse.statusCode) else {
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
          (200...299).contains(httpResponse.statusCode) else {
      throw MicrosoftAuthError.xstsAuthFailed
    }

    return try JSONDecoder().decode(XBLResponse.self, from: data)
  }

  // MARK: - Step 6: Authenticate with Minecraft

  /// Authenticates with Minecraft using XSTS token
  func authenticateWithMinecraft(userHash: String, xstsToken: String) async throws -> MinecraftAuthResponse {
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
          (200...299).contains(httpResponse.statusCode) else {
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
          (200...299).contains(httpResponse.statusCode) else {
      throw MicrosoftAuthError.profileFetchFailed
    }

    return try JSONDecoder().decode(MinecraftProfileResponse.self, from: data)
  }

  // MARK: - Complete Login Flow

  /// Completes the entire login flow from authorization code to profile
  func completeLogin(authCode: String, codeVerifier: String) async throws -> CompleteLoginResponse {
    // Step 3: Get authorization token
    let tokenResponse = try await getAuthorizationToken(authCode: authCode, codeVerifier: codeVerifier)

    // Step 4: Authenticate with XBL
    let xblResponse = try await authenticateWithXBL(accessToken: tokenResponse.accessToken)
    let xblToken = xblResponse.token
    let userHash = xblResponse.displayClaims.xui[0].uhs

    // Step 5: Authenticate with XSTS
    let xstsResponse = try await authenticateWithXSTS(xblToken: xblToken)
    let xstsToken = xstsResponse.token

    // Step 6: Authenticate with Minecraft
    let minecraftAuth = try await authenticateWithMinecraft(userHash: userHash, xstsToken: xstsToken)

    // Check if access token is present (indicates success)
    guard !minecraftAuth.accessToken.isEmpty else {
      throw MicrosoftAuthError.azureAppNotPermitted
    }

    // Step 7: Get Minecraft profile
    let profile = try await getProfile(accessToken: minecraftAuth.accessToken)

    return CompleteLoginResponse(
      id: profile.id,
      name: profile.name,
      accessToken: minecraftAuth.accessToken,
      refreshToken: tokenResponse.refreshToken,
      skins: profile.skins,
      capes: profile.capes
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

    request.httpBody = parameters
      .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
      .joined(separator: "&")
      .data(using: .utf8)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
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

    let minecraftAuth = try await authenticateWithMinecraft(userHash: userHash, xstsToken: xstsToken)
    let profile = try await getProfile(accessToken: minecraftAuth.accessToken)

    return CompleteLoginResponse(
      id: profile.id,
      name: profile.name,
      accessToken: minecraftAuth.accessToken,
      refreshToken: tokenResponse.refreshToken,
      skins: profile.skins,
      capes: profile.capes
    )
  }

  // MARK: - Helper Functions

  /// Generates a random state for CSRF protection
  private func generateState() -> String {
    let bytes = (0..<16).map { _ in UInt8.random(in: 0...255) }
    return Data(bytes).base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }

  /// Generates a code verifier for PKCE
  private func generateCodeVerifier() -> String {
    let bytes = (0..<96).map { _ in UInt8.random(in: 0...255) }
    let base64 = Data(bytes).base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
    return String(base64.prefix(128))
  }

  /// Generates a code challenge from code verifier using SHA256
  private func generateCodeChallenge(from verifier: String) -> String {
    let data = Data(verifier.utf8)
    let hash = SHA256.hash(data: data)
    let base64 = Data(hash).base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
    return base64
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
