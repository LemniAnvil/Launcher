//
//  MicrosoftAuthEdgeCaseTests.swift
//  LauncherTests
//
//  Edge case, mock reset, and response validation tests for Microsoft Authentication
//

import MojangAPI
import XCTest

@testable import Launcher

final class MicrosoftAuthEdgeCaseTests: XCTestCase {
  var mockAuthManager: MockMicrosoftAuthManager!

  override func setUpWithError() throws {
    try super.setUpWithError()
    mockAuthManager = MockMicrosoftAuthManager()
  }

  override func tearDownWithError() throws {
    mockAuthManager = nil
    try super.tearDownWithError()
  }

  // MARK: - Mock Reset Tests

  func testMockReset_ResetsAllCounters() async throws {
    // Given
    _ = try await mockAuthManager.getAuthorizationToken(authCode: "test", codeVerifier: "test")
    _ = try await mockAuthManager.authenticateWithXBL(accessToken: "test")

    // When
    mockAuthManager.reset()

    // Then
    XCTAssertEqual(mockAuthManager.getAuthorizationTokenCallCount, 0)
    XCTAssertEqual(mockAuthManager.authenticateWithXBLCallCount, 0)
    XCTAssertEqual(mockAuthManager.authenticateWithXSTSCallCount, 0)
    XCTAssertEqual(mockAuthManager.authenticateWithMinecraftCallCount, 0)
    XCTAssertEqual(mockAuthManager.getProfileCallCount, 0)
  }

  func testMockReset_ResetsAllFlags() {
    // Given
    mockAuthManager.shouldFailGetAuthorizationToken = true
    mockAuthManager.shouldFailXBLAuth = true
    mockAuthManager.shouldFailXSTSAuth = true

    // When
    mockAuthManager.reset()

    // Then
    XCTAssertFalse(mockAuthManager.shouldFailGetAuthorizationToken)
    XCTAssertFalse(mockAuthManager.shouldFailXBLAuth)
    XCTAssertFalse(mockAuthManager.shouldFailXSTSAuth)
    XCTAssertFalse(mockAuthManager.shouldFailMinecraftAuth)
    XCTAssertFalse(mockAuthManager.shouldFailProfileFetch)
    XCTAssertFalse(mockAuthManager.shouldFailRefreshToken)
  }

  // MARK: - Edge Case Tests

  func testCompleteLogin_EmptyAuthCode_StillCallsAPI() async throws {
    // Given
    let authCode = ""
    let codeVerifier = "test_code_verifier"

    // When
    _ = try await mockAuthManager.completeLogin(authCode: authCode, codeVerifier: codeVerifier)

    // Then
    XCTAssertEqual(
      mockAuthManager.getAuthorizationTokenCallCount, 1, "Should still attempt API call")
  }

  func testCompleteLogin_EmptyCodeVerifier_StillCallsAPI() async throws {
    // Given
    let authCode = "test_auth_code"
    let codeVerifier = ""

    // When
    _ = try await mockAuthManager.completeLogin(authCode: authCode, codeVerifier: codeVerifier)

    // Then
    XCTAssertEqual(
      mockAuthManager.getAuthorizationTokenCallCount, 1, "Should still attempt API call")
  }

  func testCompleteRefresh_EmptyRefreshToken_StillCallsAPI() async throws {
    // Given
    let refreshToken = ""

    // When
    _ = try await mockAuthManager.completeRefresh(refreshToken: refreshToken)

    // Then
    XCTAssertEqual(
      mockAuthManager.refreshAuthorizationTokenCallCount, 1, "Should still attempt API call")
  }

  // MARK: - Response Validation Tests

  func testCompleteLogin_ResponseContainsAllRequiredFields() async throws {
    // Given
    let authCode = "test_auth_code"
    let codeVerifier = "test_code_verifier"

    mockAuthManager.mockCompleteLoginResponse = CompleteLoginResponse(
      id: "test_uuid",
      name: "TestPlayer",
      accessToken: "test_access_token",
      refreshToken: "test_refresh_token",
      skins: nil,
      capes: nil
    )

    // When
    let response = try await mockAuthManager.completeLogin(
      authCode: authCode, codeVerifier: codeVerifier)

    // Then
    XCTAssertFalse(response.id.isEmpty, "ID should not be empty")
    XCTAssertFalse(response.name.isEmpty, "Name should not be empty")
    XCTAssertFalse(response.accessToken.isEmpty, "Access token should not be empty")
    XCTAssertFalse(response.refreshToken.isEmpty, "Refresh token should not be empty")
  }

  func testCompleteLogin_ResponseWithSkinsAndCapes() async throws {
    // Given
    let authCode = "test_auth_code"
    let codeVerifier = "test_code_verifier"

    let mockSkin = MinecraftProfileResponse.Skin(
      id: "skin_id",
      state: "ACTIVE",
      url: "https://textures.minecraft.net/texture/skin",
      variant: "CLASSIC",
      alias: "default"
    )

    let mockCape = MinecraftProfileResponse.Cape(
      id: "cape_id",
      state: "ACTIVE",
      url: "https://textures.minecraft.net/texture/cape",
      alias: "migrator"
    )

    mockAuthManager.mockCompleteLoginResponse = CompleteLoginResponse(
      id: "test_uuid",
      name: "TestPlayer",
      accessToken: "test_access_token",
      refreshToken: "test_refresh_token",
      skins: [mockSkin],
      capes: [mockCape]
    )

    // When
    let response = try await mockAuthManager.completeLogin(
      authCode: authCode, codeVerifier: codeVerifier)

    // Then
    XCTAssertNotNil(response.skins, "Skins should not be nil")
    XCTAssertNotNil(response.capes, "Capes should not be nil")
    XCTAssertEqual(response.skins?.count, 1, "Should have 1 skin")
    XCTAssertEqual(response.capes?.count, 1, "Should have 1 cape")
    XCTAssertEqual(response.skins?.first?.state, "ACTIVE")
    XCTAssertEqual(response.capes?.first?.state, "ACTIVE")
  }
}
