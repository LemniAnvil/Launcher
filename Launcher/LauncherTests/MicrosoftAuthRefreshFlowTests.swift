//
//  MicrosoftAuthRefreshFlowTests.swift
//  LauncherTests
//
//  Refresh token flow and individual step tests for Microsoft Authentication
//

import MojangAPI
import XCTest

@testable import Launcher

final class MicrosoftAuthRefreshFlowTests: XCTestCase {
  var mockAuthManager: MockMicrosoftAuthManager!

  override func setUpWithError() throws {
    try super.setUpWithError()
    mockAuthManager = MockMicrosoftAuthManager()
  }

  override func tearDownWithError() throws {
    mockAuthManager = nil
    try super.tearDownWithError()
  }

  // MARK: - Refresh Token Flow Tests

  func testCompleteRefresh_Success_ReturnsCompleteLoginResponse() async throws {
    // Given
    let refreshToken = "test_refresh_token"

    mockAuthManager.mockCompleteLoginResponse = CompleteLoginResponse(
      id: "test_uuid",
      name: "TestPlayer",
      accessToken: "new_access_token",
      refreshToken: "new_refresh_token",
      skins: nil,
      capes: nil
    )

    // When
    let response = try await mockAuthManager.completeRefresh(refreshToken: refreshToken)

    // Then
    XCTAssertEqual(response.id, "test_uuid")
    XCTAssertEqual(response.name, "TestPlayer")
    XCTAssertEqual(response.accessToken, "new_access_token")
    XCTAssertEqual(response.refreshToken, "new_refresh_token")
    XCTAssertEqual(mockAuthManager.completeRefreshCallCount, 1)
  }

  func testCompleteRefresh_CallsAllStepsInOrder() async throws {
    // Given
    let refreshToken = "test_refresh_token"

    // When
    _ = try await mockAuthManager.completeRefresh(refreshToken: refreshToken)

    // Then
    XCTAssertEqual(
      mockAuthManager.refreshAuthorizationTokenCallCount, 1, "Should call refreshAuthorizationToken"
    )
    XCTAssertEqual(
      mockAuthManager.authenticateWithXBLCallCount, 1, "Should call authenticateWithXBL")
    XCTAssertEqual(
      mockAuthManager.authenticateWithXSTSCallCount, 1, "Should call authenticateWithXSTS")
    XCTAssertEqual(
      mockAuthManager.authenticateWithMinecraftCallCount, 1, "Should call authenticateWithMinecraft"
    )
    XCTAssertEqual(mockAuthManager.getProfileCallCount, 1, "Should call getProfile")
  }

  func testCompleteRefresh_InvalidRefreshToken_ThrowsError() async {
    // Given
    let refreshToken = "invalid_refresh_token"
    mockAuthManager.shouldFailRefreshToken = true

    // When/Then
    do {
      _ = try await mockAuthManager.completeRefresh(refreshToken: refreshToken)
      XCTFail("Should throw error")
    } catch {
      XCTAssertEqual(error as? MicrosoftAuthError, .invalidRefreshToken)
    }
  }

  func testCompleteRefresh_XBLAuthFails_ThrowsError() async {
    // Given
    let refreshToken = "test_refresh_token"
    mockAuthManager.shouldFailXBLAuth = true

    // When/Then
    do {
      _ = try await mockAuthManager.completeRefresh(refreshToken: refreshToken)
      XCTFail("Should throw error")
    } catch {
      XCTAssertEqual(error as? MicrosoftAuthError, .xblAuthFailed)
    }
  }

  // MARK: - Individual Step Tests

  func testGetAuthorizationToken_Success_ReturnsTokenResponse() async throws {
    // Given
    let authCode = "test_auth_code"
    let codeVerifier = "test_code_verifier"

    // When
    let response = try await mockAuthManager.getAuthorizationToken(
      authCode: authCode, codeVerifier: codeVerifier)

    // Then
    XCTAssertEqual(response.accessToken, "mock_access_token")
    XCTAssertEqual(response.tokenType, "Bearer")
    XCTAssertEqual(response.expiresIn, 3600)
    XCTAssertEqual(response.refreshToken, "mock_refresh_token")
    XCTAssertEqual(mockAuthManager.getAuthorizationTokenCallCount, 1)
  }

  func testAuthenticateWithXBL_Success_ReturnsXBLResponse() async throws {
    // Given
    let accessToken = "test_access_token"

    // When
    let response = try await mockAuthManager.authenticateWithXBL(accessToken: accessToken)

    // Then
    XCTAssertEqual(response.token, "mock_xbl_token")
    XCTAssertEqual(response.displayClaims.xui.first?.uhs, "mock_user_hash")
    XCTAssertEqual(mockAuthManager.authenticateWithXBLCallCount, 1)
  }

  func testAuthenticateWithXSTS_Success_ReturnsXSTSResponse() async throws {
    // Given
    let xblToken = "test_xbl_token"

    // When
    let response = try await mockAuthManager.authenticateWithXSTS(xblToken: xblToken)

    // Then
    XCTAssertEqual(response.token, "mock_xsts_token")
    XCTAssertEqual(response.displayClaims.xui.first?.uhs, "mock_user_hash")
    XCTAssertEqual(mockAuthManager.authenticateWithXSTSCallCount, 1)
  }

  func testAuthenticateWithMinecraft_Success_ReturnsMinecraftAuthResponse() async throws {
    // Given
    let userHash = "test_user_hash"
    let xstsToken = "test_xsts_token"

    // When
    let response = try await mockAuthManager.authenticateWithMinecraft(
      userHash: userHash, xstsToken: xstsToken)

    // Then
    XCTAssertEqual(response.username, "MockPlayer")
    XCTAssertEqual(response.accessToken, "mock_minecraft_access_token")
    XCTAssertEqual(response.tokenType, "Bearer")
    XCTAssertEqual(mockAuthManager.authenticateWithMinecraftCallCount, 1)
  }

  func testGetProfile_Success_ReturnsProfileResponse() async throws {
    // Given
    let accessToken = "test_access_token"

    // When
    let response = try await mockAuthManager.getProfile(accessToken: accessToken)

    // Then
    XCTAssertEqual(response.id, "00000000000000000000000000000000")
    XCTAssertEqual(response.name, "MockPlayer")
    XCTAssertNotNil(response.skins)
    XCTAssertEqual(response.skins?.count, 1)
    XCTAssertEqual(mockAuthManager.getProfileCallCount, 1)
  }

  func testRefreshAuthorizationToken_Success_ReturnsNewTokens() async throws {
    // Given
    let refreshToken = "test_refresh_token"

    // When
    let response = try await mockAuthManager.refreshAuthorizationToken(refreshToken: refreshToken)

    // Then
    XCTAssertEqual(response.accessToken, "mock_refreshed_access_token")
    XCTAssertEqual(response.refreshToken, "mock_new_refresh_token")
    XCTAssertEqual(mockAuthManager.refreshAuthorizationTokenCallCount, 1)
  }
}
