//
//  AuthenticationServiceTests.swift
//  MojangAPI
//

import XCTest

@testable import MojangAPI

final class AuthenticationServiceTests: XCTestCase {
  var authService: AuthenticationService!

  override func setUp() {
    super.setUp()
    authService = AuthenticationService()
  }

  override func tearDown() {
    authService = nil
    super.tearDown()
  }

  // MARK: - Microsoft OAuth Tests

  func testGetMicrosoftAuthorizationURL_Success() {
    // Arrange
    let clientId = "test-client-id"
    let redirectUri = "http://localhost:8080/callback"
    let codeChallenge = "test-code-challenge"
    let state = "test-state"

    // Act
    let url = authService.getMicrosoftAuthorizationURL(
      clientId: clientId,
      redirectUri: redirectUri,
      codeChallenge: codeChallenge,
      state: state
    )

    // Assert
    XCTAssertNotNil(url)
    XCTAssertTrue(url!.absoluteString.contains("login.microsoftonline.com"))
    XCTAssertTrue(url!.absoluteString.contains("client_id=\(clientId)"))
    XCTAssertTrue(
      url!.absoluteString.contains("code_challenge=\(codeChallenge)")
    )
    XCTAssertTrue(url!.absoluteString.contains("state=\(state)"))
  }

  func testGetMicrosoftAuthorizationURL_ContainsRequiredParameters() {
    // Arrange
    let clientId = "test-client-id"
    let redirectUri = "http://localhost:8080/callback"
    let codeChallenge = "test-code-challenge"
    let state = "test-state"

    // Act
    let url = authService.getMicrosoftAuthorizationURL(
      clientId: clientId,
      redirectUri: redirectUri,
      codeChallenge: codeChallenge,
      state: state
    )

    // Assert
    let urlString = url!.absoluteString
    XCTAssertTrue(urlString.contains("response_type=code"))
    XCTAssertTrue(urlString.contains("scope=XboxLive.signin"))
    XCTAssertTrue(urlString.contains("code_challenge_method=S256"))
  }

  // MARK: - Xbox Live Authentication Tests

  func testAuthenticateWithXboxLive_RequestFormat() {
    // Arrange
    let microsoftAccessToken = "test-access-token"

    // Act
    let request = XBLAuthRequest(accessToken: microsoftAccessToken)

    // Assert
    XCTAssertEqual(request.relyingParty, "http://auth.xboxlive.com")
    XCTAssertEqual(request.tokenType, "JWT")
    XCTAssertEqual(request.properties.authMethod, "RPS")
    XCTAssertEqual(request.properties.siteName, "user.auth.xboxlive.com")
    XCTAssertTrue(
      request.properties.rpsTicket.contains("d=\(microsoftAccessToken)")
    )
  }

  // MARK: - XSTS Authentication Tests

  func testAuthenticateWithXSTS_RequestFormat() {
    // Arrange
    let xblToken = "test-xbl-token"

    // Act
    let request = XSTSAuthRequest(xblToken: xblToken)

    // Assert
    XCTAssertEqual(request.relyingParty, "rp://api.minecraftservices.com/")
    XCTAssertEqual(request.tokenType, "JWT")
    XCTAssertEqual(request.properties.sandboxId, "RETAIL")
    XCTAssertEqual(request.properties.userTokens.count, 1)
    XCTAssertEqual(request.properties.userTokens[0], xblToken)
  }

  // MARK: - Minecraft Authentication Tests

  func testAuthenticateWithMinecraft_IdentityTokenFormat() {
    // Arrange
    let userHash = "test-user-hash"
    let xstsToken = "test-xsts-token"

    // Act
    let request = MinecraftAuthRequest(
      identityToken: "XBL3.0 x=\(userHash);\(xstsToken)"
    )

    // Assert
    XCTAssertTrue(request.identityToken.contains("XBL3.0"))
    XCTAssertTrue(request.identityToken.contains("x=\(userHash)"))
    XCTAssertTrue(request.identityToken.contains(xstsToken))
  }

  // MARK: - Mojang Authentication Tests

  func testAuthenticateWithMojang_RequestFormat() {
    // Arrange
    let username = "test@example.com"
    let password = "test-password"
    let clientToken = "test-client-token"

    // Act
    let request = MojangAuthRequest(
      username: username,
      password: password,
      clientToken: clientToken
    )

    // Assert
    XCTAssertEqual(request.username, username)
    XCTAssertEqual(request.password, password)
    XCTAssertEqual(request.clientToken, clientToken)
    XCTAssertTrue(request.requestUser)
  }

  // MARK: - Token Response Tests

  func testMicrosoftTokenResponse_Decoding() throws {
    // Arrange
    let json = """
      {
          "token_type": "Bearer",
          "expires_in": 3600,
          "scope": "XboxLive.signin offline_access",
          "access_token": "test-access-token",
          "refresh_token": "test-refresh-token",
          "ext_expires_in": 3600
      }
      """

    // Act
    let decoder = JSONDecoder()
    let response = try decoder.decode(
      MicrosoftTokenResponse.self,
      from: json.data(using: .utf8)!
    )

    // Assert
    XCTAssertEqual(response.tokenType, "Bearer")
    XCTAssertEqual(response.expiresIn, 3600)
    XCTAssertEqual(response.accessToken, "test-access-token")
    XCTAssertEqual(response.refreshToken, "test-refresh-token")
  }

  func testXBLAuthResponse_Decoding() throws {
    // Arrange
    let json = """
      {
          "issueInstant": "2021-01-01T00:00:00Z",
          "notAfter": "2021-01-02T00:00:00Z",
          "token": "test-xbl-token",
          "displayClaims": {
              "xui": [
                  {
                      "uhs": "test-user-hash"
                  }
              ]
          }
      }
      """

    // Act
    let decoder = JSONDecoder()
    let response = try decoder.decode(
      XBLAuthResponse.self,
      from: json.data(using: .utf8)!
    )

    // Assert
    XCTAssertEqual(response.token, "test-xbl-token")
    XCTAssertEqual(response.displayClaims.xui.count, 1)
    XCTAssertEqual(response.displayClaims.xui[0].uhs, "test-user-hash")
  }

  func testMinecraftAuthResponse_Decoding() throws {
    // Arrange
    let json = """
      {
          "username": "test-username",
          "roles": ["user"],
          "access_token": "test-access-token",
          "token_type": "Bearer",
          "expires_in": 86400
      }
      """

    // Act
    let decoder = JSONDecoder()
    let response = try decoder.decode(
      MinecraftAuthResponse.self,
      from: json.data(using: .utf8)!
    )

    // Assert
    XCTAssertEqual(response.username, "test-username")
    XCTAssertEqual(response.accessToken, "test-access-token")
    XCTAssertEqual(response.tokenType, "Bearer")
    XCTAssertEqual(response.expiresIn, 86400)
  }

  // MARK: - Error Handling Tests

  func testMojangAPIError_NetworkError() {
    // Arrange
    let urlError = URLError(.notConnectedToInternet)
    let error = MojangAPIError.networkError(urlError)

    // Assert
    XCTAssertNotNil(error.errorDescription)
    let description = error.errorDescription?.lowercased() ?? ""
    XCTAssertTrue(description.contains("network"), "Error description should contain 'network'")
  }

  func testMojangAPIError_Unauthorized() {
    // Arrange
    let error = MojangAPIError.unauthorized

    // Assert
    XCTAssertNotNil(error.errorDescription)
    XCTAssertTrue(error.errorDescription!.contains("Unauthorized"))
  }

  func testMojangAPIError_RateLimited() {
    // Arrange
    let error = MojangAPIError.rateLimited

    // Assert
    XCTAssertNotNil(error.errorDescription)
    let description = error.errorDescription?.lowercased() ?? ""
    XCTAssertTrue(
      description.contains("rate") || description.contains("frequent"),
      "Error description should contain 'rate' or 'frequent'"
    )
  }

  func testMojangAPIError_TokenExpired() {
    // Arrange
    let error = MojangAPIError.tokenExpired

    // Assert
    XCTAssertNotNil(error.errorDescription)
    let description = error.errorDescription?.lowercased() ?? ""
    XCTAssertTrue(description.contains("token") && description.contains("expired"))
  }
}
