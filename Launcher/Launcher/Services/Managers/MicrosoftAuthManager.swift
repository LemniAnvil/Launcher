//
//  MicrosoftAuthManager.swift
//  Launcher
//
//  Microsoft Account Authentication Manager
//  Implements OAuth 2.0 + Xbox Live + Minecraft Services authentication flow
//

import CraftKit
import Foundation

// MARK: - Secure Login Data

struct SecureLoginData {
  let url: String
  let state: String
  let codeVerifier: String
}

// MARK: - Auth Configuration

struct AuthConfiguration {
  let clientID: String
  let redirectURI: String
  let scope: String

  init(
    clientID: String,
    redirectURI: String = "LemniAnvil-launcher://auth",
    scope: String = "XboxLive.signin offline_access"
  ) {
    self.clientID = clientID
    self.redirectURI = redirectURI
    self.scope = scope
  }

  static func fromBundle(_ bundle: Bundle = .main) -> Self? {
    guard let clientID = bundle.infoDictionary?["MicrosoftClientID"] as? String,
      !clientID.isEmpty,
      !clientID.contains("YOUR_"),
      !clientID.contains("00000000-0000-0000-0000-000000000000")
    else {
      return nil
    }
    return Self(clientID: clientID)
  }

  static func fromBundleOrFatal(_ bundle: Bundle = .main) -> Self {
    guard let config = fromBundle(bundle) else {
      fatalError(
        """
        ❌ Microsoft Client ID not configured!

        Please follow these steps:
        1. Ensure Config.xcconfig exists and contains MICROSOFT_CLIENT_ID
        2. Replace YOUR_MICROSOFT_CLIENT_ID_HERE with your actual client ID
        3. Configure the xcconfig file in Xcode project settings
        4. Clean build folder (⌘⇧K) and rebuild

        Get your client ID from: https://portal.azure.com/
        """
      )
    }
    return config
  }
}

// MARK: - Microsoft Authentication Manager

class MicrosoftAuthManager: MicrosoftAuthProtocol {
  // swiftlint:disable:previous type_body_length

  static let shared = MicrosoftAuthManager(configuration: .fromBundleOrFatal())

  // Authentication Configuration
  private let configuration: AuthConfiguration

  // CraftKit Microsoft Auth Client
  private let authClient: MicrosoftAuthClient

  private var clientID: String { configuration.clientID }
  private var redirectURI: String { configuration.redirectURI }
  private var scope: String { configuration.scope }

  init(configuration: AuthConfiguration) {
    self.configuration = configuration
    self.authClient = MicrosoftAuthClient(
      clientID: configuration.clientID,
      redirectURI: configuration.redirectURI,
      scope: configuration.scope,
      session: URLSessionFactory.createSession()
    )
  }

  // MARK: - Step 1: Generate Secure Login Data

  /// Generates secure login data with PKCE and state for authentication
  func getSecureLoginData() throws -> SecureLoginData {
    // Use CraftKit's MicrosoftAuthClient to generate login URL
    let loginData = try authClient.generateLoginURL()

    return SecureLoginData(
      url: loginData.url.absoluteString,
      state: loginData.state,
      codeVerifier: loginData.codeVerifier
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
  func getAuthorizationToken(
    authCode: String,
    codeVerifier: String
  ) async throws -> AuthorizationTokenResponse {
    return try await authClient.exchangeAuthorizationCode(
      authCode: authCode,
      codeVerifier: codeVerifier
    )
  }

  // MARK: - Step 4: Authenticate with Xbox Live

  /// Authenticates with Xbox Live using Microsoft access token
  func authenticateWithXBL(accessToken: String) async throws -> XBLAuthResponse {
    return try await authClient.authenticateWithXboxLive(accessToken: accessToken)
  }

  // MARK: - Step 5: Authenticate with XSTS

  /// Authenticates with XSTS using XBL token
  func authenticateWithXSTS(xblToken: String) async throws -> XBLAuthResponse {
    return try await authClient.authenticateWithXSTS(xblToken: xblToken)
  }

  // MARK: - Step 6: Authenticate with Minecraft

  /// Authenticates with Minecraft using XSTS token
  func authenticateWithMinecraft(userHash: String, xstsToken: String) async throws
    -> MinecraftAuthResponse
  {
    return try await authClient.authenticateWithMinecraft(
      userHash: userHash,
      xstsToken: xstsToken
    )
  }

  // MARK: - Step 7: Get Minecraft Profile

  /// Gets Minecraft profile using Minecraft access token
  func getProfile(accessToken: String) async throws -> MinecraftProfileResponse {
    return try await authClient.fetchMinecraftProfile(accessToken: accessToken)
  }

  // MARK: - Complete Login Flow

  /// Completes the entire login flow from authorization code to profile
  func completeLogin(authCode: String, codeVerifier: String) async throws -> CompleteLoginResponse {
    // Use CraftKit's MicrosoftAuthClient to complete the login flow
    return try await authClient.completeLogin(
      authCode: authCode,
      codeVerifier: codeVerifier
    )
  }

  // MARK: - Refresh Token Flow

  /// Refreshes authentication using refresh token
  func refreshAuthorizationToken(refreshToken: String) async throws -> AuthorizationTokenResponse {
    return try await authClient.refreshMicrosoftToken(refreshToken: refreshToken)
  }

  /// Completes refresh flow to get new access token and profile
  func completeRefresh(refreshToken: String) async throws -> CompleteLoginResponse {
    // Use CraftKit's MicrosoftAuthClient to refresh the login
    return try await authClient.refreshLogin(refreshToken: refreshToken)
  }

  // MARK: - Helper Functions

  /// Converts MinecraftProfileResponse to CompleteLoginResponse
  func buildCompleteLoginResponse(
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
