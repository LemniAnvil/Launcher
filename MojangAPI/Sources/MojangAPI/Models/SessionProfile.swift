//
//  SessionProfile.swift
//  MojangAPI
//

import Foundation

/// Player Profile Returned by Session Server (includes Texture Information)
public struct SessionProfile: Codable {
  public let id: String
  public let name: String
  public let properties: [ProfileProperty]

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case properties
  }

  public init(id: String, name: String, properties: [ProfileProperty]) {
    self.id = id
    self.name = name
    self.properties = properties
  }
}

/// Profile Properties
public struct ProfileProperty: Codable {
  public let name: String
  public let value: String
  public let signature: String?

  enum CodingKeys: String, CodingKey {
    case name
    case value
    case signature
  }

  public init(name: String, value: String, signature: String? = nil) {
    self.name = name
    self.value = value
    self.signature = signature
  }
}

/// Texture Properties (Base64 Encoded)
public struct TexturesProperty: Codable {
  public let timestamp: Date
  public let profileId: String
  public let profileName: String
  public let textures: Textures
  public let signatureRequired: Bool?

  enum CodingKeys: String, CodingKey {
    case timestamp
    case profileId
    case profileName
    case textures
    case signatureRequired
  }

  public init(
    timestamp: Date,
    profileId: String,
    profileName: String,
    textures: Textures,
    signatureRequired: Bool? = nil
  ) {
    self.timestamp = timestamp
    self.profileId = profileId
    self.profileName = profileName
    self.textures = textures
    self.signatureRequired = signatureRequired
  }
}

/// Texture Information
public struct Textures: Codable {
  public let skin: TextureInfo?
  public let cape: TextureInfo?

  enum CodingKeys: String, CodingKey {
    case skin = "SKIN"
    case cape = "CAPE"
  }

  public init(skin: TextureInfo? = nil, cape: TextureInfo? = nil) {
    self.skin = skin
    self.cape = cape
  }
}

/// Individual Texture Information
public struct TextureInfo: Codable {
  public let url: URL
  public let metadata: TextureMetadata?

  enum CodingKeys: String, CodingKey {
    case url
    case metadata
  }

  public init(url: URL, metadata: TextureMetadata? = nil) {
    self.url = url
    self.metadata = metadata
  }
}

/// Texture Metadata
public struct TextureMetadata: Codable {
  public let model: String?

  enum CodingKeys: String, CodingKey {
    case model
  }

  public init(model: String? = nil) {
    self.model = model
  }
}
