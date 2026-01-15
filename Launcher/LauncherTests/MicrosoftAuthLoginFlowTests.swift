//
//  MicrosoftAuthLoginFlowTests.swift
//  LauncherTests
//
//  Complete login flow tests for Microsoft Authentication
//

import CraftKit
import XCTest

@testable import Launcher

final class MicrosoftAuthLoginFlowTests: XCTestCase {
  var mockAuthManager: MockMicrosoftAuthManager!

  override func setUpWithError() throws {
    try super.setUpWithError()
    mockAuthManager = MockMicrosoftAuthManager()
  }

  override func tearDownWithError() throws {
    mockAuthManager = nil
    try super.tearDownWithError()
  }

  // MARK: - Complete Login Flow Tests

  func testCompleteLogin_Success_ReturnsCompleteLoginResponse() async throws {
    // Given
    let authCode = "test_auth_code"
    let codeVerifier = "test_code_verifier"

    mockAuthManager.mockCompleteLoginResponse = CompleteLoginResponse(
      id: "test_uuid",
      name: "TestPlayer",
      accessToken: "test_access_token",
      refreshToken: "test_refresh_token",
      skins: [
        MinecraftProfileResponse.Skin(
          id: "skin_id",
          state: "ACTIVE",
          url: "https://textures.minecraft.net/texture/test",
          variant: "CLASSIC",
          alias: nil
        )
      ],
      capes: nil
    )

    // When
    let response = try await mockAuthManager.completeLogin(
      authCode: authCode, codeVerifier: codeVerifier)

    // Then
    XCTAssertEqual(response.id, "test_uuid")
    XCTAssertEqual(response.name, "TestPlayer")
    XCTAssertEqual(response.accessToken, "test_access_token")
    XCTAssertEqual(response.refreshToken, "test_refresh_token")
    XCTAssertEqual(response.skins?.count, 1)
    XCTAssertEqual(mockAuthManager.completeLoginCallCount, 1)
  }

  func testCompleteLogin_CallsAllStepsInOrder() async throws {
    // Given
    let authCode = "test_auth_code"
    let codeVerifier = "test_code_verifier"

    // When
    _ = try await mockAuthManager.completeLogin(authCode: authCode, codeVerifier: codeVerifier)

    // Then
    XCTAssertEqual(
      mockAuthManager.getAuthorizationTokenCallCount, 1, "Should call getAuthorizationToken")
    XCTAssertEqual(
      mockAuthManager.authenticateWithXBLCallCount, 1, "Should call authenticateWithXBL")
    XCTAssertEqual(
      mockAuthManager.authenticateWithXSTSCallCount, 1, "Should call authenticateWithXSTS")
    XCTAssertEqual(
      mockAuthManager.authenticateWithMinecraftCallCount, 1, "Should call authenticateWithMinecraft"
    )
    XCTAssertEqual(mockAuthManager.getProfileCallCount, 1, "Should call getProfile")
  }

  func testCompleteLogin_GetAuthorizationTokenFails_ThrowsError() async {
    // Given
    let authCode = "test_auth_code"
    let codeVerifier = "test_code_verifier"
    mockAuthManager.shouldFailGetAuthorizationToken = true

    // When/Then
    do {
      _ = try await mockAuthManager.completeLogin(authCode: authCode, codeVerifier: codeVerifier)
      XCTFail("Should throw error")
    } catch {
      XCTAssertEqual(error as? MicrosoftAuthError, .httpError)
    }
  }

  func testCompleteLogin_XBLAuthFails_ThrowsError() async {
    // Given
    let authCode = "test_auth_code"
    let codeVerifier = "test_code_verifier"
    mockAuthManager.shouldFailXBLAuth = true

    // When/Then
    do {
      _ = try await mockAuthManager.completeLogin(authCode: authCode, codeVerifier: codeVerifier)
      XCTFail("Should throw error")
    } catch {
      XCTAssertEqual(error as? MicrosoftAuthError, .xblAuthFailed)
    }
  }

  func testCompleteLogin_XSTSAuthFails_ThrowsError() async {
    // Given
    let authCode = "test_auth_code"
    let codeVerifier = "test_code_verifier"
    mockAuthManager.shouldFailXSTSAuth = true

    // When/Then
    do {
      _ = try await mockAuthManager.completeLogin(authCode: authCode, codeVerifier: codeVerifier)
      XCTFail("Should throw error")
    } catch {
      XCTAssertEqual(error as? MicrosoftAuthError, .xstsAuthFailed)
    }
  }

  func testCompleteLogin_MinecraftAuthFails_ThrowsError() async {
    // Given
    let authCode = "test_auth_code"
    let codeVerifier = "test_code_verifier"
    mockAuthManager.shouldFailMinecraftAuth = true

    // When/Then
    do {
      _ = try await mockAuthManager.completeLogin(authCode: authCode, codeVerifier: codeVerifier)
      XCTFail("Should throw error")
    } catch {
      XCTAssertEqual(error as? MicrosoftAuthError, .minecraftAuthFailed)
    }
  }

  func testCompleteLogin_ProfileFetchFails_ThrowsError() async {
    // Given
    let authCode = "test_auth_code"
    let codeVerifier = "test_code_verifier"
    mockAuthManager.shouldFailProfileFetch = true

    // When/Then
    do {
      _ = try await mockAuthManager.completeLogin(authCode: authCode, codeVerifier: codeVerifier)
      XCTFail("Should throw error")
    } catch {
      XCTAssertEqual(error as? MicrosoftAuthError, .profileFetchFailed)
    }
  }
}
