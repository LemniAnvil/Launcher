//
//  MicrosoftAuthManagerTests.swift
//  LauncherTests
//
//  Unit tests for Microsoft Authentication Manager
//

import MojangAPI
import XCTest

@testable import Launcher

final class MicrosoftAuthManagerTests: XCTestCase {
  var sut: MicrosoftAuthManager!

  override func setUpWithError() throws {
    try super.setUpWithError()
    sut = MicrosoftAuthManager.shared
  }

  override func tearDownWithError() throws {
    sut = nil
    try super.tearDownWithError()
  }

  // MARK: - PKCE Generation Tests

  func testGetSecureLoginData_GeneratesValidData() throws {
    // When
    let loginData = try sut.getSecureLoginData()

    // Then
    XCTAssertFalse(loginData.url.isEmpty, "URL should not be empty")
    XCTAssertFalse(loginData.state.isEmpty, "State should not be empty")
    XCTAssertFalse(loginData.codeVerifier.isEmpty, "Code verifier should not be empty")
  }

  func testGetSecureLoginData_URLContainsRequiredParameters() throws {
    // When
    let loginData = try sut.getSecureLoginData()

    // Then
    XCTAssertTrue(loginData.url.contains("client_id="), "URL should contain client_id")
    XCTAssertTrue(loginData.url.contains("response_type=code"), "URL should contain response_type")
    XCTAssertTrue(loginData.url.contains("redirect_uri="), "URL should contain redirect_uri")
    XCTAssertTrue(loginData.url.contains("scope="), "URL should contain scope")
    XCTAssertTrue(loginData.url.contains("state="), "URL should contain state")
    XCTAssertTrue(loginData.url.contains("code_challenge="), "URL should contain code_challenge")
    XCTAssertTrue(
      loginData.url.contains("code_challenge_method=S256"), "URL should use S256 method")
  }

  func testGetSecureLoginData_GeneratesUniqueState() throws {
    // When
    let loginData1 = try sut.getSecureLoginData()
    let loginData2 = try sut.getSecureLoginData()

    // Then
    XCTAssertNotEqual(loginData1.state, loginData2.state, "Each call should generate unique state")
  }

  func testGetSecureLoginData_GeneratesUniqueCodeVerifier() throws {
    // When
    let loginData1 = try sut.getSecureLoginData()
    let loginData2 = try sut.getSecureLoginData()

    // Then
    XCTAssertNotEqual(
      loginData1.codeVerifier, loginData2.codeVerifier,
      "Each call should generate unique code verifier")
  }

  func testGetSecureLoginData_StateIsBase64URLSafe() throws {
    // When
    let loginData = try sut.getSecureLoginData()

    // Then
    XCTAssertFalse(loginData.state.contains("+"), "State should not contain +")
    XCTAssertFalse(loginData.state.contains("/"), "State should not contain /")
    XCTAssertFalse(loginData.state.contains("="), "State should not contain =")
  }

  func testGetSecureLoginData_CodeVerifierIsBase64URLSafe() throws {
    // When
    let loginData = try sut.getSecureLoginData()

    // Then
    XCTAssertFalse(loginData.codeVerifier.contains("+"), "Code verifier should not contain +")
    XCTAssertFalse(loginData.codeVerifier.contains("/"), "Code verifier should not contain /")
    XCTAssertFalse(loginData.codeVerifier.contains("="), "Code verifier should not contain =")
  }

  func testGetSecureLoginData_CodeVerifierHasCorrectLength() throws {
    // When
    let loginData = try sut.getSecureLoginData()

    // Then
    // PKCE spec requires code verifier to be 43-128 characters
    XCTAssertGreaterThanOrEqual(
      loginData.codeVerifier.count, 43, "Code verifier should be at least 43 characters")
    XCTAssertLessThanOrEqual(
      loginData.codeVerifier.count, 128, "Code verifier should be at most 128 characters")
  }

  // MARK: - URL Parsing Tests

  func testParseAuthCodeURL_ValidURL_ReturnsAuthCode() throws {
    // Given
    let expectedState = "test_state_123"
    let expectedCode = "auth_code_456"
    let urlString = "LemniAnvil-launcher://auth?code=\(expectedCode)&state=\(expectedState)"

    // When
    let authCode = try sut.parseAuthCodeURL(urlString, expectedState: expectedState)

    // Then
    XCTAssertEqual(authCode, expectedCode, "Should extract correct auth code")
  }

  func testParseAuthCodeURL_InvalidURL_ThrowsError() {
    // Given
    // Use a URL that cannot be parsed by URLComponents
    let invalidURL = "://invalid"
    let expectedState = "test_state"

    // When/Then
    XCTAssertThrowsError(try sut.parseAuthCodeURL(invalidURL, expectedState: expectedState)) {
      error in
      // Should throw either invalidURL or authCodeNotFound error
      XCTAssertTrue(
        error is MicrosoftAuthError,
        "Should throw MicrosoftAuthError"
      )
    }
  }

  func testParseAuthCodeURL_StateMismatch_ThrowsError() {
    // Given
    let expectedState = "correct_state"
    let actualState = "wrong_state"
    let urlString = "LemniAnvil-launcher://auth?code=auth_code&state=\(actualState)"

    // When/Then
    XCTAssertThrowsError(try sut.parseAuthCodeURL(urlString, expectedState: expectedState)) {
      error in
      XCTAssertEqual(
        error as? MicrosoftAuthError, .stateMismatch, "Should throw stateMismatch error")
    }
  }

  func testParseAuthCodeURL_MissingAuthCode_ThrowsError() {
    // Given
    let expectedState = "test_state"
    let urlString = "LemniAnvil-launcher://auth?state=\(expectedState)"

    // When/Then
    XCTAssertThrowsError(try sut.parseAuthCodeURL(urlString, expectedState: expectedState)) {
      error in
      XCTAssertEqual(
        error as? MicrosoftAuthError, .authCodeNotFound, "Should throw authCodeNotFound error")
    }
  }

  func testParseAuthCodeURL_URLEncodedParameters_DecodesCorrectly() throws {
    // Given
    let expectedState = "test_state_123"
    let expectedCode = "auth_code_with_special_chars"
    let urlString = "LemniAnvil-launcher://auth?code=\(expectedCode)&state=\(expectedState)"

    // When
    let authCode = try sut.parseAuthCodeURL(urlString, expectedState: expectedState)

    // Then
    XCTAssertEqual(authCode, expectedCode, "Should decode URL-encoded parameters correctly")
  }

  // MARK: - Response Model Tests

  func testAuthorizationTokenResponse_Decoding() throws {
    // Given
    let json = """
      {
        "access_token": "test_access_token",
        "token_type": "Bearer",
        "expires_in": 3600,
        "scope": "XboxLive.signin offline_access",
        "refresh_token": "test_refresh_token"
      }
      """
    let data = json.data(using: .utf8)!

    // When
    let response = try JSONDecoder().decode(AuthorizationTokenResponse.self, from: data)

    // Then
    XCTAssertEqual(response.accessToken, "test_access_token")
    XCTAssertEqual(response.tokenType, "Bearer")
    XCTAssertEqual(response.expiresIn, 3600)
    XCTAssertEqual(response.scope, "XboxLive.signin offline_access")
    XCTAssertEqual(response.refreshToken, "test_refresh_token")
  }

  func testXBLResponse_Decoding() throws {
    // Given
    let json = """
      {
        "IssueInstant": "2024-01-01T00:00:00.0000000Z",
        "NotAfter": "2024-01-02T00:00:00.0000000Z",
        "Token": "test_xbl_token",
        "DisplayClaims": {
          "xui": [
            {
              "uhs": "test_user_hash"
            }
          ]
        }
      }
      """
    let data = json.data(using: .utf8)!

    // When
    let response = try JSONDecoder().decode(XBLResponse.self, from: data)

    // Then
    XCTAssertEqual(response.issueInstant, "2024-01-01T00:00:00.0000000Z")
    XCTAssertEqual(response.notAfter, "2024-01-02T00:00:00.0000000Z")
    XCTAssertEqual(response.token, "test_xbl_token")
    XCTAssertEqual(response.displayClaims.xui.first?.uhs, "test_user_hash")
  }

  func testMinecraftAuthResponse_Decoding() throws {
    // Given
    let json = """
      {
        "username": "TestPlayer",
        "roles": [],
        "access_token": "test_minecraft_token",
        "token_type": "Bearer",
        "expires_in": 86400
      }
      """
    let data = json.data(using: .utf8)!

    // When
    let response = try JSONDecoder().decode(MinecraftAuthResponse.self, from: data)

    // Then
    XCTAssertEqual(response.username, "TestPlayer")
    XCTAssertEqual(response.accessToken, "test_minecraft_token")
    XCTAssertEqual(response.tokenType, "Bearer")
    XCTAssertEqual(response.expiresIn, 86400)
  }

  func testMinecraftProfileResponse_Decoding() throws {
    // Given
    let json = """
      {
        "id": "00000000000000000000000000000000",
        "name": "TestPlayer",
        "skins": [
          {
            "id": "skin_id",
            "state": "ACTIVE",
            "url": "https://textures.minecraft.net/texture/test",
            "variant": "CLASSIC",
            "alias": null
          }
        ],
        "capes": []
      }
      """
    let data = json.data(using: .utf8)!

    // When
    let response = try JSONDecoder().decode(MinecraftProfileResponse.self, from: data)

    // Then
    XCTAssertEqual(response.id, "00000000000000000000000000000000")
    XCTAssertEqual(response.name, "TestPlayer")
    XCTAssertEqual(response.skins?.count, 1)
    XCTAssertEqual(response.skins?.first?.state, "ACTIVE")
  }

  // MARK: - Error Handling Tests

  func testMicrosoftAuthError_LocalizedDescription() {
    // Given/When/Then
    XCTAssertEqual(MicrosoftAuthError.invalidURL.errorDescription, "Invalid URL")
    XCTAssertEqual(
      MicrosoftAuthError.stateMismatch.errorDescription, "State mismatch - possible CSRF attack")
    XCTAssertEqual(
      MicrosoftAuthError.authCodeNotFound.errorDescription,
      "Authorization code not found in callback URL")
    XCTAssertEqual(MicrosoftAuthError.httpError.errorDescription, "HTTP error occurred")
    XCTAssertEqual(
      MicrosoftAuthError.xblAuthFailed.errorDescription, "Xbox Live authentication failed")
    XCTAssertEqual(MicrosoftAuthError.xstsAuthFailed.errorDescription, "XSTS authentication failed")
    XCTAssertEqual(
      MicrosoftAuthError.minecraftAuthFailed.errorDescription, "Minecraft authentication failed")
    XCTAssertEqual(
      MicrosoftAuthError.profileFetchFailed.errorDescription, "Failed to fetch Minecraft profile")
    XCTAssertEqual(
      MicrosoftAuthError.azureAppNotPermitted.errorDescription,
      "Azure application not permitted to access Minecraft API")
    XCTAssertEqual(
      MicrosoftAuthError.accountNotOwnMinecraft.errorDescription, "Account does not own Minecraft")
    XCTAssertEqual(
      MicrosoftAuthError.invalidRefreshToken.errorDescription, "Invalid or expired refresh token")
  }

  // MARK: - SecureLoginData Tests

  func testSecureLoginData_Initialization() {
    // Given
    let url = "https://test.com"
    let state = "test_state"
    let codeVerifier = "test_verifier"

    // When
    let loginData = SecureLoginData(url: url, state: state, codeVerifier: codeVerifier)

    // Then
    XCTAssertEqual(loginData.url, url)
    XCTAssertEqual(loginData.state, state)
    XCTAssertEqual(loginData.codeVerifier, codeVerifier)
  }
}
