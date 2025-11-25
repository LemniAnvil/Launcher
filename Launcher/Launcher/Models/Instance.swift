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

  /// Directory name for this instance (e.g., "1.20.1-a3f2c9")
  let directoryName: String

  /// Creation date
  let createdAt: Date

  /// Last modified date
  var lastModified: Date

  /// Initialize instance
  init(name: String, versionId: String) {
    let uuid = UUID().uuidString
    self.id = uuid
    self.name = name
    self.versionId = versionId
    // Generate directory name: "versionId-shortId" (first 6 chars of UUID)
    let shortId = String(uuid.prefix(8).filter { $0 != "-" })
    self.directoryName = "\(versionId)-\(shortId)"
    self.createdAt = Date()
    self.lastModified = Date()
  }

  /// Initialize instance with custom directory name (for migration/import)
  init(name: String, versionId: String, directoryName: String) {
    self.id = UUID().uuidString
    self.name = name
    self.versionId = versionId
    self.directoryName = directoryName
    self.createdAt = Date()
    self.lastModified = Date()
  }

  /// Initialize from decoder
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    name = try container.decode(String.self, forKey: .name)
    versionId = try container.decode(String.self, forKey: .versionId)

    // Handle directoryName for backward compatibility
    if let directoryName = try? container.decode(String.self, forKey: .directoryName) {
      self.directoryName = directoryName
    } else {
      // Fallback for old instances without directoryName: use name
      // This will be migrated on next save
      self.directoryName = name
    }

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
    try container.encode(directoryName, forKey: .directoryName)
    try container.encode(createdAt.timeIntervalSince1970, forKey: .createdAt)
    try container.encode(lastModified.timeIntervalSince1970, forKey: .lastModified)
  }

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case versionId
    case directoryName
    case createdAt
    case lastModified
  }
}
