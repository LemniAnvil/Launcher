import XCTest
@testable import MojangAPI

final class PlayerServiceTests: XCTestCase {
    var playerService: PlayerService!
    var mockClient: MockMojangAPIClient!

    override func setUp() {
        super.setUp()
        mockClient = MockMojangAPIClient()
        playerService = PlayerService(client: mockClient)
    }

    override func tearDown() {
        playerService = nil
        mockClient = nil
        super.tearDown()
    }

    // MARK: - getPlayerUUID Tests

    func testGetPlayerUUID_Success() async throws {
        // Arrange
        let expectedResponse = PlayerUUIDResponse(
            id: UUID(uuidString: "069a79f4-44e9-405c-98c9-d58ab183bfe9")!,
            name: "Steve"
        )
        mockClient.mockResponse = expectedResponse

        // Act
        let result = try await playerService.getPlayerUUID(name: "Steve")

        // Assert
        XCTAssertEqual(result.id, expectedResponse.id)
        XCTAssertEqual(result.name, expectedResponse.name)
        XCTAssertEqual(mockClient.lastEndpoint, .getPlayerUUID(name: "Steve"))
    }

    func testGetPlayerUUID_NetworkError() async {
        // Arrange
        mockClient.mockError = MojangAPIError.networkError(
            URLError(.notConnectedToInternet)
        )

        // Act & Assert
        do {
            _ = try await playerService.getPlayerUUID(name: "Steve")
            XCTFail("Expected error to be thrown")
        } catch let error as MojangAPIError {
            if case .networkError = error {
                // Success
            } else {
                XCTFail("Expected networkError, got \(error)")
            }
        } catch {
            XCTFail("Expected MojangAPIError, got \(error)")
        }
    }

    func testGetPlayerUUID_NotFound() async {
        // Arrange
        mockClient.mockError = MojangAPIError.notFound

        // Act & Assert
        do {
            _ = try await playerService.getPlayerUUID(name: "InvalidPlayer")
            XCTFail("Expected error to be thrown")
        } catch let error as MojangAPIError {
            if case .notFound = error {
                // Success
            } else {
                XCTFail("Expected notFound, got \(error)")
            }
        } catch {
            XCTFail("Expected MojangAPIError, got \(error)")
        }
    }

    // MARK: - getPlayerProfile Tests

    func testGetPlayerProfile_Success() async throws {
        // Arrange
        let sessionProfile = SessionProfile(
            id: "069a79f4-44e9-405c-98c9-d58ab183bfe9",
            name: "Steve",
            properties: [
                ProfileProperty(
                    name: "textures",
                    value: createBase64TexturesProperty(),
                    signature: nil
                )
            ]
        )
        mockClient.mockResponse = sessionProfile

        // Act
        let uuid = UUID(uuidString: "069a79f4-44e9-405c-98c9-d58ab183bfe9")!
        let result = try await playerService.getPlayerProfile(uuid: uuid)

        // Assert
        XCTAssertEqual(result.name, "Steve")
        XCTAssertEqual(result.id, uuid)
        XCTAssertFalse(result.skins.isEmpty)
      debugPrint(result.skins)
    }

    func testGetPlayerProfile_NoSkin() async throws {
        // Arrange
        let sessionProfile = SessionProfile(
            id: "069a79f4-44e9-405c-98c9-d58ab183bfe9",
            name: "Steve",
            properties: []
        )
        mockClient.mockResponse = sessionProfile

        // Act
        let uuid = UUID(uuidString: "069a79f4-44e9-405c-98c9-d58ab183bfe9")!
        let result = try await playerService.getPlayerProfile(uuid: uuid)

        // Assert
        XCTAssertEqual(result.name, "Steve")
        XCTAssertTrue(result.skins.isEmpty)
        XCTAssertTrue(result.capes.isEmpty)
    }

    func testGetPlayerProfile_InvalidUUID() async throws {
        // Arrange
        let sessionProfile = SessionProfile(
            id: "invalid-uuid",
            name: "Steve",
            properties: []
        )
        mockClient.mockResponse = sessionProfile

        // Act
        let uuid = UUID(uuidString: "069a79f4-44e9-405c-98c9-d58ab183bfe9")!
        let result = try await playerService.getPlayerProfile(uuid: uuid)

        // Assert - When response ID is invalid, a new UUID is generated
        // So we just verify the name is correct
        XCTAssertEqual(result.name, "Steve")
    }

    func testGetPlayerProfile_DecodingError() async {
        // Arrange
        mockClient.mockError = MojangAPIError.decodingError(
            DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Invalid data"
                )
            )
        )

        // Act & Assert
        do {
            let uuid = UUID(uuidString: "069a79f4-44e9-405c-98c9-d58ab183bfe9")!
            _ = try await playerService.getPlayerProfile(uuid: uuid)
            XCTFail("Expected error to be thrown")
        } catch let error as MojangAPIError {
            if case .decodingError = error {
                // Success
            } else {
                XCTFail("Expected decodingError, got \(error)")
            }
        } catch {
            XCTFail("Expected MojangAPIError, got \(error)")
        }
    }

    // MARK: - getNameHistory Tests

    func testGetNameHistory_Success() async throws {
        // Arrange
        let expectedHistory = [
            NameHistory(name: "Steve", changedToAt: nil),
            NameHistory(name: "Steve2", changedToAt: Date(timeIntervalSince1970: 1000000))
        ]
        mockClient.mockResponse = expectedHistory

        // Act
        let uuid = UUID(uuidString: "069a79f4-44e9-405c-98c9-d58ab183bfe9")!
        let result = try await playerService.getNameHistory(uuid: uuid)

        // Assert
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].name, "Steve")
        XCTAssertEqual(result[1].name, "Steve2")
    }

    func testGetNameHistory_Empty() async throws {
        // Arrange
        let expectedHistory: [NameHistory] = []
        mockClient.mockResponse = expectedHistory

        // Act
        let uuid = UUID(uuidString: "069a79f4-44e9-405c-98c9-d58ab183bfe9")!
        let result = try await playerService.getNameHistory(uuid: uuid)

        // Assert
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - getSessionProfile Tests

    func testGetSessionProfile_Success() async throws {
        // Arrange
        let expectedProfile = SessionProfile(
            id: "069a79f4-44e9-405c-98c9-d58ab183bfe9",
            name: "Steve",
            properties: [
                ProfileProperty(
                    name: "textures",
                    value: createBase64TexturesProperty(),
                    signature: nil
                )
            ]
        )
        mockClient.mockResponse = expectedProfile

        // Act
        let uuid = UUID(uuidString: "069a79f4-44e9-405c-98c9-d58ab183bfe9")!
        let result = try await playerService.getSessionProfile(uuid: uuid)

        // Assert
        XCTAssertEqual(result.id, expectedProfile.id)
        XCTAssertEqual(result.name, expectedProfile.name)
        XCTAssertEqual(result.properties.count, 1)
    }

    // MARK: - Helper Methods

    private func createBase64TexturesProperty() -> String {
        let texturesJSON = """
        {
            "timestamp": 1234567890000,
            "profileId": "069a79f4-44e9-405c-98c9-d58ab183bfe9",
            "profileName": "Steve",
            "textures": {
                "SKIN": {
                    "url": "http://textures.minecraft.net/texture/1234567890"
                }
            }
        }
        """
        return Data(texturesJSON.utf8).base64EncodedString()
    }
}

// MARK: - Mock Client

class MockMojangAPIClient: MojangAPIClientProtocol {
    var mockResponse: Any?
    var mockError: Error?
    var lastEndpoint: MojangEndpoint?

    func request<T: Decodable>(_ endpoint: MojangEndpoint, body: Encodable?) async throws -> T {
        lastEndpoint = endpoint

        if let error = mockError {
            throw error
        }

        guard let response = mockResponse as? T else {
            throw MojangAPIError.unknown("Mock response type mismatch")
        }

        return response
    }

    func request(_ endpoint: MojangEndpoint, body: Encodable?) async throws -> Data {
        lastEndpoint = endpoint

        if let error = mockError {
            throw error
        }

        throw MojangAPIError.unknown("Mock data response not configured")
    }
}
