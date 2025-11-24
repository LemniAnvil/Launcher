//
//  UUIDExtensionTests.swift
//  MojangAPI
//

import XCTest

@testable import MojangAPI

final class UUIDExtensionTests: XCTestCase {

  // MARK: - UUID(flexibleString:) Tests

  func testFlexibleUUID_WithHyphens_Success() {
    // Arrange
    let uuidString = "069a79f4-44e9-405c-98c9-d58ab183bfe9"

    // Act
    let uuid = UUID(flexibleString: uuidString)

    // Assert
    XCTAssertNotNil(uuid)
    XCTAssertEqual(uuid?.uuidString.lowercased(), uuidString.lowercased())
  }

  func testFlexibleUUID_WithoutHyphens_Success() {
    // Arrange
    let uuidStringNoHyphens = "069a79f444e9405c98c9d58ab183bfe9"
    let expectedUUID = "069a79f4-44e9-405c-98c9-d58ab183bfe9"

    // Act
    let uuid = UUID(flexibleString: uuidStringNoHyphens)

    // Assert
    XCTAssertNotNil(uuid)
    XCTAssertEqual(uuid?.uuidString.lowercased(), expectedUUID.lowercased())
  }

  func testFlexibleUUID_UppercaseWithoutHyphens_Success() {
    // Arrange
    let uuidStringNoHyphens = "069A79F444E9405C98C9D58AB183BFE9"
    let expectedUUID = "069a79f4-44e9-405c-98c9-d58ab183bfe9"

    // Act
    let uuid = UUID(flexibleString: uuidStringNoHyphens)

    // Assert
    XCTAssertNotNil(uuid)
    XCTAssertEqual(uuid?.uuidString.lowercased(), expectedUUID.lowercased())
  }

  func testFlexibleUUID_MixedCaseWithHyphens_Success() {
    // Arrange
    let uuidString = "069A79F4-44E9-405C-98C9-D58AB183BFE9"

    // Act
    let uuid = UUID(flexibleString: uuidString)

    // Assert
    XCTAssertNotNil(uuid)
    XCTAssertEqual(uuid?.uuidString.uppercased(), uuidString.uppercased())
  }

  func testFlexibleUUID_InvalidLength_TooShort() {
    // Arrange
    let shortString = "069a79f444e9405c98c9"

    // Act
    let uuid = UUID(flexibleString: shortString)

    // Assert
    XCTAssertNil(uuid)
  }

  func testFlexibleUUID_InvalidLength_TooLong() {
    // Arrange
    let longString = "069a79f444e9405c98c9d58ab183bfe9extra"

    // Act
    let uuid = UUID(flexibleString: longString)

    // Assert
    XCTAssertNil(uuid)
  }

  func testFlexibleUUID_InvalidCharacters() {
    // Arrange
    let invalidString = "069a79f4-44e9-405c-98c9-d58ab183bfeg"  // 'g' is not a hex digit

    // Act
    let uuid = UUID(flexibleString: invalidString)

    // Assert
    XCTAssertNil(uuid)
  }

  func testFlexibleUUID_InvalidCharactersNoHyphens() {
    // Arrange
    let invalidString = "069a79f444e9405c98c9d58ab183bfeg"  // 'g' is not a hex digit

    // Act
    let uuid = UUID(flexibleString: invalidString)

    // Assert
    XCTAssertNil(uuid)
  }

  func testFlexibleUUID_EmptyString() {
    // Arrange
    let emptyString = ""

    // Act
    let uuid = UUID(flexibleString: emptyString)

    // Assert
    XCTAssertNil(uuid)
  }

  func testFlexibleUUID_PartialHyphens() {
    // Arrange - UUID with some but not all hyphens is invalid for standard init
    let partialString = "069a79f4-44e9405c-98c9-d58ab183bfe9"

    // Act
    let uuid = UUID(flexibleString: partialString)

    // Assert
    // Should fail because it contains hyphens but not in the right places
    XCTAssertNil(uuid)
  }

  // MARK: - Real UUID Format Tests

  func testFlexibleUUID_RealMinecraftUUID_Notch() {
    // Arrange - Notch's UUID
    let notchUUID = "069a79f444e9409c98c9d58ab183bfe9"

    // Act
    let uuid = UUID(flexibleString: notchUUID)

    // Assert
    XCTAssertNotNil(uuid)
  }

  func testFlexibleUUID_RealMinecraftUUID_WithHyphens() {
    // Arrange - UUID with hyphens
    let hyphenatedUUID = "069a79f4-44e9-409c-98c9-d58ab183bfe9"

    // Act
    let uuid = UUID(flexibleString: hyphenatedUUID)

    // Assert
    XCTAssertNotNil(uuid)
  }

  // MARK: - Consistency Tests

  func testFlexibleUUID_ConsistencyBetweenFormats() {
    // Arrange
    let withHyphens = "069a79f4-44e9-405c-98c9-d58ab183bfe9"
    let withoutHyphens = "069a79f444e9405c98c9d58ab183bfe9"

    // Act
    let uuid1 = UUID(flexibleString: withHyphens)
    let uuid2 = UUID(flexibleString: withoutHyphens)

    // Assert
    XCTAssertNotNil(uuid1)
    XCTAssertNotNil(uuid2)
    XCTAssertEqual(uuid1, uuid2, "Both formats should produce the same UUID")
  }

  func testFlexibleUUID_MultipleParsings() {
    // Arrange
    let uuidString = "069a79f444e9405c98c9d58ab183bfe9"

    // Act
    let uuid1 = UUID(flexibleString: uuidString)
    let uuid2 = UUID(flexibleString: uuidString)

    // Assert
    XCTAssertEqual(uuid1, uuid2, "Same input should always produce same UUID")
  }

  // MARK: - Edge Cases

  func testFlexibleUUID_AllZeros() {
    // Arrange
    let allZeros = "00000000000000000000000000000000"

    // Act
    let uuid = UUID(flexibleString: allZeros)

    // Assert
    XCTAssertNotNil(uuid)
    XCTAssertEqual(
      uuid?.uuidString.lowercased(),
      "00000000-0000-0000-0000-000000000000"
    )
  }

  func testFlexibleUUID_AllFs() {
    // Arrange
    let allFs = "ffffffffffffffffffffffffffffffff"

    // Act
    let uuid = UUID(flexibleString: allFs)

    // Assert
    XCTAssertNotNil(uuid)
    XCTAssertEqual(
      uuid?.uuidString.lowercased(),
      "ffffffff-ffff-ffff-ffff-ffffffffffff"
    )
  }

  func testFlexibleUUID_SpecialCharacters() {
    // Arrange
    let specialChars = "069a79f4@44e9#405c$98c9%d58ab183bfe9"

    // Act
    let uuid = UUID(flexibleString: specialChars)

    // Assert
    XCTAssertNil(uuid)
  }

  func testFlexibleUUID_Whitespace() {
    // Arrange
    let withSpaces = "069a79f4 44e9 405c 98c9 d58ab183bfe9"

    // Act
    let uuid = UUID(flexibleString: withSpaces)

    // Assert
    XCTAssertNil(uuid)
  }

  // MARK: - Offline UUID Tests
  /*
  func testOfflineUUID_Deterministic() {
    // Arrange & Act
    let uuid1 = UUID.offline(username: "Steve")
    let uuid2 = UUID.offline(username: "Steve")

    // Assert
    XCTAssertEqual(uuid1, uuid2, "Same username should always generate the same UUID")
  }

  func testOfflineUUID_DifferentUsers() {
    // Arrange & Act
    let uuid1 = UUID.offline(username: "Steve")
    let uuid2 = UUID.offline(username: "Alex")

    // Assert
    XCTAssertNotEqual(uuid1, uuid2, "Different usernames should generate different UUIDs")
  }

  func testOfflineUUID_CaseSensitive() {
    // Arrange & Act
    let uuid1 = UUID.offline(username: "steve")
    let uuid2 = UUID.offline(username: "Steve")

    // Assert
    XCTAssertNotEqual(
      uuid1,
      uuid2,
      "UUID generation should be case-sensitive"
    )
  }

  func testOfflineUUID_EmptyUsername() {
    // Arrange & Act
    let uuid = UUID.offline(username: "")

    // Assert
    XCTAssertNotNil(uuid, "Empty username should still generate valid UUID")
  }

  func testOfflineUUID_SpecialCharacters() {
    // Arrange & Act
    let uuid1 = UUID.offline(username: "Player_123")
    let uuid2 = UUID.offline(username: "Test-Player")
    let uuid3 = UUID.offline(username: "User@Example")

    // Assert
    XCTAssertNotNil(uuid1)
    XCTAssertNotNil(uuid2)
    XCTAssertNotNil(uuid3)
    XCTAssertNotEqual(uuid1, uuid2)
    XCTAssertNotEqual(uuid2, uuid3)
  }

  func testOfflineUUID_LongUsername() {
    // Arrange
    let longUsername = String(repeating: "a", count: 100)

    // Act
    let uuid = UUID.offline(username: longUsername)

    // Assert
    XCTAssertNotNil(uuid, "Long username should generate valid UUID")
  }

  func testOfflineUUID_UnicodeCharacters() {
    // Arrange & Act
    let uuid1 = UUID.offline(username: "玩家")
    let uuid2 = UUID.offline(username: "Спартак")
    let uuid3 = UUID.offline(username: "🎮")

    // Assert
    XCTAssertNotNil(uuid1)
    XCTAssertNotNil(uuid2)
    XCTAssertNotNil(uuid3)
  }

  func testOfflineUUIDString_NoHyphens() {
    // Arrange & Act
    let uuidString = UUID.offlineString(username: "Steve")

    // Assert
    XCTAssertFalse(uuidString.contains("-"), "String version should have no hyphens")
    XCTAssertEqual(uuidString.count, 32, "String should be 32 characters")
  }

  func testOfflineUUIDString_Lowercase() {
    // Arrange & Act
    let uuidString = UUID.offlineString(username: "Steve")

    // Assert
    XCTAssertEqual(
      uuidString,
      uuidString.lowercased(),
      "String version should be lowercase"
    )
  }

  func testOfflineUUIDString_Consistency() {
    // Arrange & Act
    let uuid = UUID.offline(username: "Steve")
    let uuidString = UUID.offlineString(username: "Steve")
    let expected = uuid.uuidString.replacingOccurrences(of: "-", with: "").lowercased()

    // Assert
    XCTAssertEqual(
      uuidString,
      expected,
      "String version should be consistent with UUID version"
    )
  }

  func testOfflineUUIDString_Deterministic() {
    // Arrange & Act
    let string1 = UUID.offlineString(username: "TestPlayer")
    let string2 = UUID.offlineString(username: "TestPlayer")

    // Assert
    XCTAssertEqual(string1, string2, "String version should be deterministic")
  }

  func testOfflineUUID_HexCharactersOnly() {
    // Arrange & Act
    let uuidString = UUID.offlineString(username: "Steve")

    // Assert
    let hexCharacterSet = CharacterSet(charactersIn: "0123456789abcdef")
    let isValidHex = uuidString.unicodeScalars.allSatisfy { hexCharacterSet.contains($0) }
    XCTAssertTrue(isValidHex, "UUID string should contain only hex characters")
  }

  func testOfflineUUID_ValidUUIDFormat() {
    // Arrange & Act
    let uuid = UUID.offline(username: "TestUser")

    // Assert
    // Verify it can be converted back to UUID string and parsed
    let uuidString = uuid.uuidString
    let reparsed = UUID(uuidString: uuidString)
    XCTAssertNotNil(reparsed, "Generated UUID should have valid format")
    XCTAssertEqual(uuid, reparsed, "UUID should be parseable")
  }

  func testOfflineUUID_MultipleCallsWithDifferentUsers() {
    // Arrange
    let usernames = ["Alice", "Bob", "Charlie", "Dave", "Eve"]
    var uuids: Set<UUID> = []

    // Act
    for username in usernames {
      let uuid = UUID.offline(username: username)
      uuids.insert(uuid)
    }

    // Assert
    XCTAssertEqual(
      uuids.count,
      usernames.count,
      "Each unique username should produce a unique UUID"
    )
  }

  func testOfflineUUID_ConsistencyAcrossCalls() {
    // Arrange
    let username = "ConsistencyTest"
    let iterations = 100
    var uuids: [UUID] = []

    // Act
    for _ in 0..<iterations {
      uuids.append(UUID.offline(username: username))
    }

    // Assert
    let uniqueUUIDs = Set(uuids)
    XCTAssertEqual(
      uniqueUUIDs.count,
      1,
      "All iterations should produce the same UUID for the same username"
    )
  }
  */
}

