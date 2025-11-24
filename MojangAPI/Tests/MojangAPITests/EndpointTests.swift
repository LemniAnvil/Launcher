//
//  EndpointTests.swift
//  MojangAPI
//

import XCTest

@testable import MojangAPI

final class EndpointTests: XCTestCase {

  // MARK: - URL Building Tests

  func testGetPlayerUUID_BuildURL() throws {
    // Arrange
    let endpoint = MojangEndpoint.getPlayerUUID(name: "Steve")

    // Act
    let url = try endpoint.buildURL()

    // Assert
    XCTAssertEqual(url.scheme, "https")
    XCTAssertEqual(url.host, "api.mojang.com")
    XCTAssertTrue(url.path.contains("/users/profiles/minecraft/Steve"))
  }

  func testGetPlayerUUID_URL() throws {
    // Arrange
    let endpoint = MojangEndpoint.getPlayerUUID(name: "Steve")

    // Act
    let url = try endpoint.buildURL()

    // Assert
    XCTAssertEqual(url.absoluteString, "https://api.mojang.com/users/profiles/minecraft/Steve")
    XCTAssertNil(url.query)
  }

  func testGetPlayerProfile_URL() throws {
    // Arrange
    let uuid = UUID(uuidString: "069a79f4-44e9-405c-98c9-d58ab183bfe9")!
    let endpoint = MojangEndpoint.getPlayerProfile(uuid: uuid)

    // Act
    let url = try endpoint.buildURL()

    // Assert
    XCTAssertEqual(url.scheme, "https")
    XCTAssertEqual(url.host, "api.mojang.com")
    XCTAssertTrue(url.path.contains("/users/profiles/minecraft/"))
    // Should contain UUID without hyphens (uppercase from uuidString)
    XCTAssertTrue(url.path.uppercased().contains("069A79F444E9405C98C9D58AB183BFE9"))
  }

  func testGetSessionProfile_BuildURL_RemovesHyphens() throws {
    // Arrange
    let uuid = UUID(uuidString: "069a79f4-44e9-405c-98c9-d58ab183bfe9")!
    let endpoint = MojangEndpoint.getSessionProfile(uuid: uuid)

    // Act
    let url = try endpoint.buildURL()

    // Assert
    XCTAssertEqual(url.scheme, "https")
    XCTAssertEqual(url.host, "sessionserver.mojang.com")
    XCTAssertTrue(url.path.contains("/session/minecraft/profile/"))
    // IMPORTANT: UUID should NOT contain hyphens in the path (uppercase from uuidString)
    XCTAssertTrue(url.path.uppercased().contains("069A79F444E9405C98C9D58AB183BFE9"))
    XCTAssertFalse(url.path.contains("-"))
  }

  func testGetNameHistory_BuildURL() throws {
    // Arrange
    let uuid = UUID(uuidString: "069a79f4-44e9-405c-98c9-d58ab183bfe9")!
    let endpoint = MojangEndpoint.getNameHistory(uuid: uuid)

    // Act
    let url = try endpoint.buildURL()

    // Assert
    XCTAssertEqual(url.scheme, "https")
    XCTAssertEqual(url.host, "api.mojang.com")
    XCTAssertTrue(url.path.contains("/user/profiles/"))
    XCTAssertTrue(url.path.contains("/names"))
  }

  // MARK: - HTTP Method Tests

  func testGetPlayerUUID_HTTPMethod() {
    // Arrange
    let endpoint = MojangEndpoint.getPlayerUUID(name: "Steve")

    // Act
    let method = endpoint.method

    // Assert
    XCTAssertEqual(method, "GET")
  }

  func testGetPlayerProfile_HTTPMethod() {
    // Arrange
    let uuid = UUID(uuidString: "069a79f4-44e9-405c-98c9-d58ab183bfe9")!
    let endpoint = MojangEndpoint.getPlayerProfile(uuid: uuid)

    // Act
    let method = endpoint.method

    // Assert
    XCTAssertEqual(method, "GET")
  }

  func testGetSessionProfile_HTTPMethod() {
    // Arrange
    let uuid = UUID(uuidString: "069a79f4-44e9-405c-98c9-d58ab183bfe9")!
    let endpoint = MojangEndpoint.getSessionProfile(uuid: uuid)

    // Act
    let method = endpoint.method

    // Assert
    XCTAssertEqual(method, "GET")
  }

  func testAuthenticateMojang_HTTPMethod() {
    // Arrange
    let endpoint = MojangEndpoint.authenticateMojang(
      username: "test",
      password: "test",
      clientToken: "test"
    )

    // Act
    let method = endpoint.method

    // Assert
    XCTAssertEqual(method, "POST")
  }

  // MARK: - Base URL Tests

  func testGetPlayerUUID_BaseURL() {
    // Arrange
    let endpoint = MojangEndpoint.getPlayerUUID(name: "Steve")

    // Act
    let baseURL = endpoint.baseURL

    // Assert
    XCTAssertEqual(baseURL.absoluteString, "https://api.mojang.com")
  }

  func testGetSessionProfile_BaseURL() {
    // Arrange
    let uuid = UUID(uuidString: "069a79f4-44e9-405c-98c9-d58ab183bfe9")!
    let endpoint = MojangEndpoint.getSessionProfile(uuid: uuid)

    // Act
    let baseURL = endpoint.baseURL

    // Assert
    XCTAssertEqual(baseURL.absoluteString, "https://sessionserver.mojang.com")
  }

  func testAuthenticateMojang_BaseURL() {
    // Arrange
    let endpoint = MojangEndpoint.authenticateMojang(
      username: "test",
      password: "test",
      clientToken: "test"
    )

    // Act
    let baseURL = endpoint.baseURL

    // Assert
    XCTAssertEqual(baseURL.absoluteString, "https://authserver.mojang.com")
  }

  func testMicrosoftOAuth_BaseURL() {
    // Arrange
    let endpoint = MojangEndpoint.microsoftOAuthAuthorize

    // Act
    let baseURL = endpoint.baseURL

    // Assert
    XCTAssertEqual(
      baseURL.absoluteString,
      "https://login.microsoftonline.com"
    )
  }

  func testXboxLive_BaseURL() {
    // Arrange
    let endpoint = MojangEndpoint.xboxLiveAuthenticate

    // Act
    let baseURL = endpoint.baseURL

    // Assert
    XCTAssertEqual(baseURL.absoluteString, "https://user.auth.xboxlive.com")
  }

  func testXSTS_BaseURL() {
    // Arrange
    let endpoint = MojangEndpoint.xstsAuthenticate

    // Act
    let baseURL = endpoint.baseURL

    // Assert
    XCTAssertEqual(baseURL.absoluteString, "https://xsts.auth.xboxlive.com")
  }

  func testMinecraftService_BaseURL() {
    // Arrange
    let endpoint = MojangEndpoint.minecraftServiceAuthenticate

    // Act
    let baseURL = endpoint.baseURL

    // Assert
    XCTAssertEqual(
      baseURL.absoluteString,
      "https://api.minecraftservices.com"
    )
  }

  // MARK: - Authentication Requirements Tests

  func testGetPlayerUUID_NoAuthRequired() {
    // Arrange
    let endpoint = MojangEndpoint.getPlayerUUID(name: "Steve")

    // Act
    let requiresAuth = endpoint.requiresAuthentication

    // Assert
    XCTAssertFalse(requiresAuth)
  }

  func testGetSessionProfile_NoAuthRequired() {
    // Arrange
    let uuid = UUID(uuidString: "069a79f4-44e9-405c-98c9-d58ab183bfe9")!
    let endpoint = MojangEndpoint.getSessionProfile(uuid: uuid)

    // Act
    let requiresAuth = endpoint.requiresAuthentication

    // Assert
    XCTAssertFalse(requiresAuth)
  }

  func testValidateSession_RequiresAuth() {
    // Arrange
    let uuid = UUID(uuidString: "069a79f4-44e9-405c-98c9-d58ab183bfe9")!
    let endpoint = MojangEndpoint.validateSession(
      accessToken: "test",
      selectedProfile: uuid
    )

    // Act
    let requiresAuth = endpoint.requiresAuthentication

    // Assert
    XCTAssertTrue(requiresAuth)
  }

  func testGetMinecraftProfile_RequiresAuth() {
    // Arrange
    let endpoint = MojangEndpoint.getMinecraftProfile

    // Act
    let requiresAuth = endpoint.requiresAuthentication

    // Assert
    XCTAssertTrue(requiresAuth)
  }

  // MARK: - Endpoint Equality Tests

  func testEndpointEquality_SameName() {
    // Arrange
    let endpoint1 = MojangEndpoint.getPlayerUUID(name: "Steve")
    let endpoint2 = MojangEndpoint.getPlayerUUID(name: "Steve")

    // Assert
    XCTAssertEqual(endpoint1, endpoint2)
  }

  func testEndpointEquality_DifferentName() {
    // Arrange
    let endpoint1 = MojangEndpoint.getPlayerUUID(name: "Steve")
    let endpoint2 = MojangEndpoint.getPlayerUUID(name: "Alex")

    // Assert
    XCTAssertNotEqual(endpoint1, endpoint2)
  }

  func testEndpointEquality_SameUUID() {
    // Arrange
    let uuid = UUID(uuidString: "069a79f4-44e9-405c-98c9-d58ab183bfe9")!
    let endpoint1 = MojangEndpoint.getSessionProfile(uuid: uuid)
    let endpoint2 = MojangEndpoint.getSessionProfile(uuid: uuid)

    // Assert
    XCTAssertEqual(endpoint1, endpoint2)
  }

  // MARK: - Path Tests

  func testGetPlayerUUID_Path() {
    // Arrange
    let endpoint = MojangEndpoint.getPlayerUUID(name: "Steve")

    // Act
    let path = endpoint.path

    // Assert
    XCTAssertEqual(path, "/users/profiles/minecraft/Steve")
  }

  func testGetSessionProfile_Path_FormatsUUID() {
    // Arrange
    let uuid = UUID(uuidString: "069a79f4-44e9-405c-98c9-d58ab183bfe9")!
    let endpoint = MojangEndpoint.getSessionProfile(uuid: uuid)

    // Act
    let path = endpoint.path

    // Assert
    // Path should contain UUID without hyphens (uppercased by uuidString property)
    XCTAssertEqual(
      path.uppercased(),
      "/session/minecraft/profile/069A79F444E9405C98C9D58AB183BFE9".uppercased()
    )
    XCTAssertFalse(path.contains("-"), "UUID should not contain hyphens")
  }

  func testGetNameHistory_Path() {
    // Arrange
    let uuid = UUID(uuidString: "069a79f4-44e9-405c-98c9-d58ab183bfe9")!
    let endpoint = MojangEndpoint.getNameHistory(uuid: uuid)

    // Act
    let path = endpoint.path

    // Assert
    XCTAssertTrue(path.contains("/user/profiles/"))
    XCTAssertTrue(path.contains("/names"))
  }

  func testAuthenticateMojang_Path() {
    // Arrange
    let endpoint = MojangEndpoint.authenticateMojang(
      username: "test",
      password: "test",
      clientToken: "test"
    )

    // Act
    let path = endpoint.path

    // Assert
    XCTAssertEqual(path, "/authenticate")
  }
}
