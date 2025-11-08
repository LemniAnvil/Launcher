//
//  Instance.swift
//  Launcher
//
//  Minecraft instance data model
//

import Foundation

/// Minecraft instance model
struct Instance: Codable, Identifiable {
  /// Unique identifier for the instance
  let id: String

  /// Display name of the instance
  let name: String

  /// Minecraft version ID this instance uses
  let versionId: String

  /// Creation date
  let createdAt: Date

  /// Last modified date
  var lastModified: Date

  /// Initialize instance
  init(name: String, versionId: String) {
    self.id = UUID().uuidString
    self.name = name
    self.versionId = versionId
    self.createdAt = Date()
    self.lastModified = Date()
  }

  /// Initialize from decoder
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    name = try container.decode(String.self, forKey: .name)
    versionId = try container.decode(String.self, forKey: .versionId)

    let createdAtTimestamp = try container.decode(TimeInterval.self, forKey: .createdAt)
    createdAt = Date(timeIntervalSince1970: createdAtTimestamp)

    let lastModifiedTimestamp = try container.decode(TimeInterval.self, forKey: .lastModified)
    lastModified = Date(timeIntervalSince1970: lastModifiedTimestamp)
  }

  /// Encode to encoder
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(name, forKey: .name)
    try container.encode(versionId, forKey: .versionId)
    try container.encode(createdAt.timeIntervalSince1970, forKey: .createdAt)
    try container.encode(lastModified.timeIntervalSince1970, forKey: .lastModified)
  }

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case versionId
    case createdAt
    case lastModified
  }
}

