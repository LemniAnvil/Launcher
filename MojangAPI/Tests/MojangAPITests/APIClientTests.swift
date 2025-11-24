//
//  APIClientTests.swift
//  MojangAPI
//

import XCTest

@testable import MojangAPI

final class APIClientTests: XCTestCase {

  // MARK: - Error Handling Tests

  func testMojangAPIError_NetworkError_Description() {
    // Arrange
    let urlError = URLError(.notConnectedToInternet)
    let error = MojangAPIError.networkError(urlError)

    // Assert
    XCTAssertNotNil(error.errorDescription)
    XCTAssertTrue(error.errorDescription!.contains("Network"))
    XCTAssertNotNil(error.failureReason)
  }

  func testMojangAPIError_HTTPError_Description() {
    // Arrange
    let error = MojangAPIError.httpError(statusCode: 500, message: "Internal Server Error")

    // Assert
    XCTAssertNotNil(error.errorDescription)
    XCTAssertTrue(error.errorDescription!.contains("500"))
    XCTAssertTrue(error.errorDescription!.contains("Internal Server Error"))
  }

  func testMojangAPIError_DecodingError_Description() {
    // Arrange
    let decodingError = DecodingError.dataCorrupted(
      DecodingError.Context(
        codingPath: [],
        debugDescription: "Invalid JSON"
      )
    )
    let error = MojangAPIError.decodingError(decodingError)

    // Assert
    XCTAssertNotNil(error.errorDescription)
    XCTAssertTrue(error.errorDescription!.contains("Decoding"))
    XCTAssertNotNil(error.failureReason)
  }

  func testMojangAPIError_APIError_Description() {
    // Arrange
    let error = MojangAPIError.apiError(
      error: "ForbiddenOperationException",
      errorMessage: "Invalid credentials",
      cause: "Invalid username or password"
    )

    // Assert
    XCTAssertNotNil(error.errorDescription)
    XCTAssertTrue(error.errorDescription!.contains("ForbiddenOperationException"))
    XCTAssertTrue(error.errorDescription!.contains("Invalid credentials"))
    XCTAssertTrue(error.errorDescription!.contains("Invalid username or password"))
  }

  func testMojangAPIError_APIError_WithoutCause() {
    // Arrange
    let error = MojangAPIError.apiError(
      error: "ForbiddenOperationException",
      errorMessage: "Invalid credentials",
      cause: nil
    )

    // Assert
    XCTAssertNotNil(error.errorDescription)
    XCTAssertTrue(error.errorDescription!.contains("ForbiddenOperationException"))
    XCTAssertTrue(error.errorDescription!.contains("Invalid credentials"))
  }

  func testMojangAPIError_InvalidURL_Description() {
    // Arrange
    let error = MojangAPIError.invalidURL

    // Assert
    XCTAssertNotNil(error.errorDescription)
    XCTAssertEqual(error.errorDescription, "Invalid URL")
  }

  func testMojangAPIError_InvalidResponse_Description() {
    // Arrange
    let error = MojangAPIError.invalidResponse

    // Assert
    XCTAssertNotNil(error.errorDescription)
    XCTAssertEqual(error.errorDescription, "Invalid Response")
  }

  func testMojangAPIError_TokenExpired_Description() {
    // Arrange
    let error = MojangAPIError.tokenExpired

    // Assert
    XCTAssertNotNil(error.errorDescription)
    XCTAssertTrue(error.errorDescription!.contains("Token"))
    XCTAssertTrue(error.errorDescription!.contains("Expired") || error.errorDescription!.contains("expired"))
    XCTAssertNotNil(error.failureReason)
  }

  func testMojangAPIError_Unauthorized_Description() {
    // Arrange
    let error = MojangAPIError.unauthorized

    // Assert
    XCTAssertNotNil(error.errorDescription)
    XCTAssertTrue(error.errorDescription!.contains("Unauthorized"))
    XCTAssertNotNil(error.failureReason)
  }

  func testMojangAPIError_NotFound_Description() {
    // Arrange
    let error = MojangAPIError.notFound

    // Assert
    XCTAssertNotNil(error.errorDescription)
    XCTAssertTrue(error.errorDescription!.contains("Not Found"))
  }

  func testMojangAPIError_RateLimited_Description() {
    // Arrange
    let error = MojangAPIError.rateLimited

    // Assert
    XCTAssertNotNil(error.errorDescription)
    XCTAssertTrue(
      error.errorDescription!.contains("Rate") ||
      error.errorDescription!.contains("Too Frequent") ||
      error.errorDescription!.contains("频繁")
    )
    XCTAssertNotNil(error.failureReason)
  }

  func testMojangAPIError_Unknown_Description() {
    // Arrange
    let message = "Custom error message"
    let error = MojangAPIError.unknown(message)

    // Assert
    XCTAssertNotNil(error.errorDescription)
    XCTAssertEqual(error.errorDescription, message)
  }

  // MARK: - MojangAPIErrorResponse Tests

  func testMojangAPIErrorResponse_Decoding() throws {
    // Arrange
    let json = """
      {
          "error": "ForbiddenOperationException",
          "errorMessage": "Invalid credentials",
          "cause": "Invalid username or password"
      }
      """

    // Act
    let decoder = JSONDecoder()
    let response = try decoder.decode(
      MojangAPIErrorResponse.self,
      from: json.data(using: .utf8)!
    )

    // Assert
    XCTAssertEqual(response.error, "ForbiddenOperationException")
    XCTAssertEqual(response.errorMessage, "Invalid credentials")
    XCTAssertEqual(response.cause, "Invalid username or password")
  }

  func testMojangAPIErrorResponse_DecodingWithoutCause() throws {
    // Arrange
    let json = """
      {
          "error": "ForbiddenOperationException",
          "errorMessage": "Invalid credentials"
      }
      """

    // Act
    let decoder = JSONDecoder()
    let response = try decoder.decode(
      MojangAPIErrorResponse.self,
      from: json.data(using: .utf8)!
    )

    // Assert
    XCTAssertEqual(response.error, "ForbiddenOperationException")
    XCTAssertEqual(response.errorMessage, "Invalid credentials")
    XCTAssertNil(response.cause)
  }

  // MARK: - JSONDecoder Extension Tests

  func testMojangDecoder_DateDecodingStrategy() throws {
    // Arrange
    let json = """
      {
          "timestamp": 1234567890000
      }
      """

    struct TestModel: Decodable {
      let timestamp: Date
    }

    // Act
    let decoder = JSONDecoder.mojangDecoder
    let model = try decoder.decode(TestModel.self, from: json.data(using: .utf8)!)

    // Assert
    // 1234567890000 milliseconds = 1234567890 seconds
    let expectedDate = Date(timeIntervalSince1970: 1234567890)
    XCTAssertEqual(model.timestamp.timeIntervalSince1970, expectedDate.timeIntervalSince1970, accuracy: 0.001)
  }

  func testMojangDecoder_IsSharedInstance() {
    // Arrange & Act
    let decoder1 = JSONDecoder.mojangDecoder
    let decoder2 = JSONDecoder.mojangDecoder

    // Assert
    XCTAssertTrue(decoder1 === decoder2, "mojangDecoder should return the same instance")
  }

  // MARK: - Error Type Matching Tests

  func testMojangAPIError_IsLocalizedError() {
    // Arrange
    let error: LocalizedError = MojangAPIError.unauthorized

    // Assert
    XCTAssertNotNil(error.errorDescription)
    XCTAssertNotNil(error.failureReason)
  }

  func testMojangAPIError_NetworkErrorType() {
    // Arrange
    let urlError = URLError(.badURL)
    let error = MojangAPIError.networkError(urlError)

    // Act
    switch error {
    case .networkError(let underlyingError):
      XCTAssertEqual(underlyingError.code, URLError.Code.badURL)
    default:
      XCTFail("Expected networkError case")
    }
  }

  func testMojangAPIError_HTTPErrorType() {
    // Arrange
    let error = MojangAPIError.httpError(statusCode: 404, message: "Not Found")

    // Act
    switch error {
    case .httpError(let statusCode, let message):
      XCTAssertEqual(statusCode, 404)
      XCTAssertEqual(message, "Not Found")
    default:
      XCTFail("Expected httpError case")
    }
  }

  func testMojangAPIError_APIErrorType() {
    // Arrange
    let error = MojangAPIError.apiError(
      error: "TestError",
      errorMessage: "Test message",
      cause: "Test cause"
    )

    // Act
    switch error {
    case .apiError(let errorCode, let message, let cause):
      XCTAssertEqual(errorCode, "TestError")
      XCTAssertEqual(message, "Test message")
      XCTAssertEqual(cause, "Test cause")
    default:
      XCTFail("Expected apiError case")
    }
  }

  // MARK: - Edge Cases

  func testMojangAPIError_EmptyUnknownMessage() {
    // Arrange
    let error = MojangAPIError.unknown("")

    // Assert
    XCTAssertNotNil(error.errorDescription)
    XCTAssertEqual(error.errorDescription, "")
  }

  func testMojangAPIError_VeryLongMessage() {
    // Arrange
    let longMessage = String(repeating: "a", count: 10000)
    let error = MojangAPIError.unknown(longMessage)

    // Assert
    XCTAssertNotNil(error.errorDescription)
    XCTAssertEqual(error.errorDescription?.count, 10000)
  }
}
