//
//  MockMicrosoftAuthManager.swift
//  LauncherTests
//
//  Mock implementation of MicrosoftAuthManager for testing
//

import CraftKit
import Foundation

@testable import Launcher

class MockMicrosoftAuthManager: MicrosoftAuthProtocol {
  // MARK: - Mock Configuration

  var shouldFailGetAuthorizationToken = false
  var shouldFailXBLAuth = false
  var shouldFailXSTSAuth = false
  var shouldFailMinecraftAuth = false
  var shouldFailProfileFetch = false
  var shouldFailRefreshToken = false

  // MARK: - Mock Data

  var mockSecureLoginData: SecureLoginData?
  var mockAuthCode: String?
  var mockAuthorizationTokenResponse: AuthorizationTokenResponse?
  var mockXBLResponse: XBLResponse?
  var mockXSTSResponse: XBLResponse?
  var mockMinecraftAuthResponse: MinecraftAuthResponse?
  var mockProfileResponse: MinecraftProfileResponse?
  var mockCompleteLoginResponse: CompleteLoginResponse?

  // MARK: - Call Tracking

  var getSecureLoginDataCallCount = 0
  var parseAuthCodeURLCallCount = 0
  var getAuthorizationTokenCallCount = 0
  var authenticateWithXBLCallCount = 0
  var authenticateWithXSTSCallCount = 0
  var authenticateWithMinecraftCallCount = 0
  var getProfileCallCount = 0
  var completeLoginCallCount = 0
  var refreshAuthorizationTokenCallCount = 0
  var completeRefreshCallCount = 0

  // MARK: - Protocol Implementation

  func getSecureLoginData() throws -> SecureLoginData {
    getSecureLoginDataCallCount += 1
    return mockSecureLoginData
      ?? SecureLoginData(
        url:
          "https://login.microsoftonline.com/consumers/oauth2/v2.0/authorize?client_id=test&response_type=code",
        state: "test_state_123",
        codeVerifier: "test_code_verifier_123"
      )
  }

  func parseAuthCodeURL(_ urlString: String, expectedState: String) throws -> String {
    parseAuthCodeURLCallCount += 1

    guard let url = URL(string: urlString),
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    else {
      throw MicrosoftAuthError.invalidURL
    }

    // Check state
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

    return mockAuthCode ?? code
  }

  func getAuthorizationToken(authCode: String, codeVerifier: String) async throws
    -> AuthorizationTokenResponse
  {
    getAuthorizationTokenCallCount += 1

    if shouldFailGetAuthorizationToken {
      throw MicrosoftAuthError.httpError
    }

    return mockAuthorizationTokenResponse
      ?? AuthorizationTokenResponse(
        accessToken: "mock_access_token",
        tokenType: "Bearer",
        expiresIn: 3600,
        scope: "XboxLive.signin offline_access",
        refreshToken: "mock_refresh_token"
      )
  }

  func authenticateWithXBL(accessToken: String) async throws -> XBLResponse {
    authenticateWithXBLCallCount += 1

    if shouldFailXBLAuth {
      throw MicrosoftAuthError.xblAuthFailed
    }

    return mockXBLResponse
      ?? XBLResponse(
        issueInstant: "2024-01-01T00:00:00.0000000Z",
        notAfter: "2024-01-02T00:00:00.0000000Z",
        token: "mock_xbl_token",
        displayClaims: XBLResponse.DisplayClaims(
          xui: [XBLResponse.UserInfo(uhs: "mock_user_hash")]
        )
      )
  }

  func authenticateWithXSTS(xblToken: String) async throws -> XBLResponse {
    authenticateWithXSTSCallCount += 1

    if shouldFailXSTSAuth {
      throw MicrosoftAuthError.xstsAuthFailed
    }

    return mockXSTSResponse
      ?? XBLResponse(
        issueInstant: "2024-01-01T00:00:00.0000000Z",
        notAfter: "2024-01-02T00:00:00.0000000Z",
        token: "mock_xsts_token",
        displayClaims: XBLResponse.DisplayClaims(
          xui: [XBLResponse.UserInfo(uhs: "mock_user_hash")]
        )
      )
  }

  func authenticateWithMinecraft(userHash: String, xstsToken: String) async throws
    -> MinecraftAuthResponse
  {
    authenticateWithMinecraftCallCount += 1

    if shouldFailMinecraftAuth {
      throw MicrosoftAuthError.minecraftAuthFailed
    }

    return mockMinecraftAuthResponse
      ?? MinecraftAuthResponse(
        username: "MockPlayer",
        roles: [],
        accessToken: "mock_minecraft_access_token",
        tokenType: "Bearer",
        expiresIn: 86400
      )
  }

  func getProfile(accessToken: String) async throws -> MinecraftProfileResponse {
    getProfileCallCount += 1

    if shouldFailProfileFetch {
      throw MicrosoftAuthError.profileFetchFailed
    }

    return mockProfileResponse
      ?? MinecraftProfileResponse(
        id: "00000000000000000000000000000000",
        name: "MockPlayer",
        skins: [
          SkinInfo(
            id: "skin_id",
            url: "https://textures.minecraft.net/texture/mock_skin",
            state: "ACTIVE",
            variant: "CLASSIC",
            alias: nil
          )
        ],
        capes: nil
      )
  }

  func completeLogin(authCode: String, codeVerifier: String) async throws -> CompleteLoginResponse {
    completeLoginCallCount += 1

    if mockCompleteLoginResponse != nil {
      return mockCompleteLoginResponse!
    }

    // Simulate the full flow
    let tokenResponse = try await getAuthorizationToken(
      authCode: authCode, codeVerifier: codeVerifier)
    let xblResponse = try await authenticateWithXBL(accessToken: tokenResponse.accessToken)
    let xstsResponse = try await authenticateWithXSTS(xblToken: xblResponse.token)
    let minecraftAuth = try await authenticateWithMinecraft(
      userHash: xblResponse.displayClaims.xui[0].uhs,
      xstsToken: xstsResponse.token
    )
    let profile = try await getProfile(accessToken: minecraftAuth.accessToken)

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
      accessToken: minecraftAuth.accessToken,
      refreshToken: tokenResponse.refreshToken,
      skins: skins,
      capes: capes
    )
  }

  func refreshAuthorizationToken(refreshToken: String) async throws -> AuthorizationTokenResponse {
    refreshAuthorizationTokenCallCount += 1

    if shouldFailRefreshToken {
      throw MicrosoftAuthError.invalidRefreshToken
    }

    return mockAuthorizationTokenResponse
      ?? AuthorizationTokenResponse(
        accessToken: "mock_refreshed_access_token",
        tokenType: "Bearer",
        expiresIn: 3600,
        scope: "XboxLive.signin offline_access",
        refreshToken: "mock_new_refresh_token"
      )
  }

  func completeRefresh(refreshToken: String) async throws -> CompleteLoginResponse {
    completeRefreshCallCount += 1

    if mockCompleteLoginResponse != nil {
      return mockCompleteLoginResponse!
    }

    // Simulate the refresh flow
    let tokenResponse = try await refreshAuthorizationToken(refreshToken: refreshToken)
    let xblResponse = try await authenticateWithXBL(accessToken: tokenResponse.accessToken)
    let xstsResponse = try await authenticateWithXSTS(xblToken: xblResponse.token)
    let minecraftAuth = try await authenticateWithMinecraft(
      userHash: xblResponse.displayClaims.xui[0].uhs,
      xstsToken: xstsResponse.token
    )
    let profile = try await getProfile(accessToken: minecraftAuth.accessToken)

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
      accessToken: minecraftAuth.accessToken,
      refreshToken: tokenResponse.refreshToken,
      skins: skins,
      capes: capes
    )
  }

  // MARK: - Helper Methods

  func reset() {
    shouldFailGetAuthorizationToken = false
    shouldFailXBLAuth = false
    shouldFailXSTSAuth = false
    shouldFailMinecraftAuth = false
    shouldFailProfileFetch = false
    shouldFailRefreshToken = false

    mockSecureLoginData = nil
    mockAuthCode = nil
    mockAuthorizationTokenResponse = nil
    mockXBLResponse = nil
    mockXSTSResponse = nil
    mockMinecraftAuthResponse = nil
    mockProfileResponse = nil
    mockCompleteLoginResponse = nil

    getSecureLoginDataCallCount = 0
    parseAuthCodeURLCallCount = 0
    getAuthorizationTokenCallCount = 0
    authenticateWithXBLCallCount = 0
    authenticateWithXSTSCallCount = 0
    authenticateWithMinecraftCallCount = 0
    getProfileCallCount = 0
    completeLoginCallCount = 0
    refreshAuthorizationTokenCallCount = 0
    completeRefreshCallCount = 0
  }
}
