//
//  ModelsTests.swift
//  MojangAPI
//

import XCTest

@testable import MojangAPI

final class ModelsTests: XCTestCase {

  // MARK: - PlayerProfile Tests

  func testPlayerProfile_Creation() {
    // Arrange
    let uuid = UUID()
    let name = "Steve"
    let skins: [Skin] = []
    let capes: [Cape] = []

    // Act
    let profile = PlayerProfile(
      id: uuid,
      name: name,
      skins: skins,
      capes: capes
    )

    // Assert
    XCTAssertEqual(profile.id, uuid)
    XCTAssertEqual(profile.name, name)
    XCTAssertTrue(profile.skins.isEmpty)
    XCTAssertTrue(profile.capes.isEmpty)
  }

  func testPlayerProfile_WithSkinAndCape() {
    // Arrange
    let uuid = UUID()
    let skinURL = URL(
      string: "http://textures.minecraft.net/texture/1234567890"
    )!
    let capeURL = URL(
      string: "http://textures.minecraft.net/texture/0987654321"
    )!

    let skin = Skin(id: "skin-1", url: skinURL, state: .active)
    let cape = Cape(id: "cape-1", url: capeURL, state: .active)

    // Act
    let profile = PlayerProfile(
      id: uuid,
      name: "Steve",
      skins: [skin],
      capes: [cape]
    )

    // Assert
    XCTAssertEqual(profile.skins.count, 1)
    XCTAssertEqual(profile.capes.count, 1)
    XCTAssertEqual(profile.skins[0].url, skinURL)
    XCTAssertEqual(profile.capes[0].url, capeURL)
  }

  // MARK: - Skin Tests

  func testSkin_Creation() {
    // Arrange
    let url = URL(string: "http://textures.minecraft.net/texture/1234567890")!

    // Act
    let skin = Skin(id: "skin-1", url: url, state: .active)

    // Assert
    XCTAssertEqual(skin.id, "skin-1")
    XCTAssertEqual(skin.url, url)
    XCTAssertEqual(skin.state, .active)
  }

  func testSkin_WithMetadata() {
    // Arrange
    let url = URL(string: "http://textures.minecraft.net/texture/1234567890")!
    let metadata = SkinMetadata(model: .alex)

    // Act
    let skin = Skin(id: "skin-1", url: url, metadata: metadata, state: .active)

    // Assert
    XCTAssertEqual(skin.metadata?.model, .alex)
  }

  func testSkinModel_Values() {
    // Assert
    XCTAssertEqual(SkinModel.steve.rawValue, "default")
    XCTAssertEqual(SkinModel.alex.rawValue, "slim")
  }

  // MARK: - Cape Tests

  func testCape_Creation() {
    // Arrange
    let url = URL(string: "http://textures.minecraft.net/texture/0987654321")!

    // Act
    let cape = Cape(id: "cape-1", url: url, state: .active)

    // Assert
    XCTAssertEqual(cape.id, "cape-1")
    XCTAssertEqual(cape.url, url)
    XCTAssertEqual(cape.state, .active)
  }

  func testCape_InactiveState() {
    // Arrange
    let url = URL(string: "http://textures.minecraft.net/texture/0987654321")!

    // Act
    let cape = Cape(id: "cape-1", url: url, state: .inactive)

    // Assert
    XCTAssertEqual(cape.state, .inactive)
  }

  // MARK: - TextureState Tests

  func testTextureState_Values() {
    // Assert
    XCTAssertEqual(TextureState.active.rawValue, "ACTIVE")
    XCTAssertEqual(TextureState.inactive.rawValue, "INACTIVE")
  }

  // MARK: - PlayerUUIDResponse Tests

  func testPlayerUUIDResponse_Creation() {
    // Arrange
    let uuid = UUID(uuidString: "069a79f4-44e9-405c-98c9-d58ab183bfe9")!
    let name = "Steve"

    // Act
    let response = PlayerUUIDResponse(id: uuid, name: name)

    // Assert
    XCTAssertEqual(response.id, uuid)
    XCTAssertEqual(response.name, name)
  }

  func testPlayerUUIDResponse_Decoding() throws {
    // Arrange
    let json = """
      {
          "id": "069a79f4-44e9-405c-98c9-d58ab183bfe9",
          "name": "Steve"
      }
      """

    // Act
    let decoder = JSONDecoder()
    let response = try decoder.decode(
      PlayerUUIDResponse.self,
      from: json.data(using: .utf8)!
    )

    // Assert
    XCTAssertEqual(response.name, "Steve")
    XCTAssertEqual(
      response.id.uuidString.lowercased(),
      "069a79f4-44e9-405c-98c9-d58ab183bfe9"
    )
  }

  // MARK: - NameHistory Tests

  func testNameHistory_Creation() {
    // Arrange
    let name = "Steve"
    let date = Date(timeIntervalSince1970: 1_000_000)

    // Act
    let history = NameHistory(name: name, changedToAt: date)

    // Assert
    XCTAssertEqual(history.name, name)
    XCTAssertEqual(history.changedToAt, date)
  }

  func testNameHistory_WithoutDate() {
    // Arrange
    let name = "Steve"

    // Act
    let history = NameHistory(name: name, changedToAt: nil)

    // Assert
    XCTAssertEqual(history.name, name)
    XCTAssertNil(history.changedToAt)
  }

  // MARK: - SessionProfile Tests

  func testSessionProfile_Creation() {
    // Arrange
    let id = "069a79f4-44e9-405c-98c9-d58ab183bfe9"
    let name = "Steve"
    let properties: [ProfileProperty] = []

    // Act
    let profile = SessionProfile(id: id, name: name, properties: properties)

    // Assert
    XCTAssertEqual(profile.id, id)
    XCTAssertEqual(profile.name, name)
    XCTAssertTrue(profile.properties.isEmpty)
  }

  func testSessionProfile_WithProperties() {
    // Arrange
    let id = "069a79f4-44e9-405c-98c9-d58ab183bfe9"
    let name = "Steve"
    let property = ProfileProperty(
      name: "textures",
      value: "base64-encoded-value"
    )
    let properties = [property]

    // Act
    let profile = SessionProfile(id: id, name: name, properties: properties)

    // Assert
    XCTAssertEqual(profile.properties.count, 1)
    XCTAssertEqual(profile.properties[0].name, "textures")
  }

  // MARK: - ProfileProperty Tests

  func testProfileProperty_Creation() {
    // Arrange
    let name = "textures"
    let value = "base64-encoded-value"
    let signature = "signature-value"

    // Act
    let property = ProfileProperty(
      name: name,
      value: value,
      signature: signature
    )

    // Assert
    XCTAssertEqual(property.name, name)
    XCTAssertEqual(property.value, value)
    XCTAssertEqual(property.signature, signature)
  }

  func testProfileProperty_WithoutSignature() {
    // Arrange
    let name = "textures"
    let value = "base64-encoded-value"

    // Act
    let property = ProfileProperty(name: name, value: value, signature: nil)

    // Assert
    XCTAssertEqual(property.name, name)
    XCTAssertEqual(property.value, value)
    XCTAssertNil(property.signature)
  }

  // MARK: - Textures Tests

  func testTextures_Creation() {
    // Arrange
    let skinURL = URL(
      string: "http://textures.minecraft.net/texture/1234567890"
    )!
    let capeURL = URL(
      string: "http://textures.minecraft.net/texture/0987654321"
    )!
    let skinInfo = TextureInfo(url: skinURL)
    let capeInfo = TextureInfo(url: capeURL)

    // Act
    let textures = Textures(skin: skinInfo, cape: capeInfo)

    // Assert
    XCTAssertEqual(textures.skin?.url, skinURL)
    XCTAssertEqual(textures.cape?.url, capeURL)
  }

  func testTextures_OnlySkin() {
    // Arrange
    let skinURL = URL(
      string: "http://textures.minecraft.net/texture/1234567890"
    )!
    let skinInfo = TextureInfo(url: skinURL)

    // Act
    let textures = Textures(skin: skinInfo, cape: nil)

    // Assert
    XCTAssertNotNil(textures.skin)
    XCTAssertNil(textures.cape)
  }

  // MARK: - TextureInfo Tests

  func testTextureInfo_Creation() {
    // Arrange
    let url = URL(string: "http://textures.minecraft.net/texture/1234567890")!
    let metadata = TextureMetadata(model: "slim")

    // Act
    let info = TextureInfo(url: url, metadata: metadata)

    // Assert
    XCTAssertEqual(info.url, url)
    XCTAssertEqual(info.metadata?.model, "slim")
  }

  func testTextureInfo_WithoutMetadata() {
    // Arrange
    let url = URL(string: "http://textures.minecraft.net/texture/1234567890")!

    // Act
    let info = TextureInfo(url: url, metadata: nil)

    // Assert
    XCTAssertEqual(info.url, url)
    XCTAssertNil(info.metadata)
  }

  // MARK: - Codable Tests

  func testPlayerProfile_Codable() throws {
    // Arrange
    let uuid = UUID()
    let profile = PlayerProfile(id: uuid, name: "Steve", skins: [], capes: [])

    // Act
    let encoder = JSONEncoder()
    let data = try encoder.encode(profile)
    let decoder = JSONDecoder()
    let decodedProfile = try decoder.decode(PlayerProfile.self, from: data)

    // Assert
    XCTAssertEqual(decodedProfile.id, profile.id)
    XCTAssertEqual(decodedProfile.name, profile.name)
  }

  func testSkin_Codable() throws {
    // Arrange
    let url = URL(string: "http://textures.minecraft.net/texture/1234567890")!
    let skin = Skin(id: "skin-1", url: url, state: .active)

    // Act
    let encoder = JSONEncoder()
    let data = try encoder.encode(skin)
    let decoder = JSONDecoder()
    let decodedSkin = try decoder.decode(Skin.self, from: data)

    // Assert
    XCTAssertEqual(decodedSkin.id, skin.id)
    XCTAssertEqual(decodedSkin.url, skin.url)
    XCTAssertEqual(decodedSkin.state, skin.state)
  }
}
