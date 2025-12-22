//
//  Instance.swift
//  Launcher
//
//  Minecraft instance data model
//

import Foundation

/// Instance source type
enum InstanceSource: String, Codable {
  case native  // Created by this launcher
  case prism  // PrismLauncher external instance
}

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

  /// Instance source (default: native)
  let source: InstanceSource

  /// External instance path (only for external instances)
  let externalPath: URL?

  /// Instance icon path (optional)
  let iconPath: URL?

  /// Whether this instance is editable (native instances only)
  var isEditable: Bool {
    source == .native
  }

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
    self.source = .native
    self.externalPath = nil
    self.iconPath = nil
  }

  /// Initialize instance with custom directory name (for migration/import)
  init(name: String, versionId: String, directoryName: String) {
    self.id = UUID().uuidString
    self.name = name
    self.versionId = versionId
    self.directoryName = directoryName
    self.createdAt = Date()
    self.lastModified = Date()
    self.source = .native
    self.externalPath = nil
    self.iconPath = nil
  }

  /// Initialize external instance (e.g., from PrismLauncher)
  init(
    name: String,
    versionId: String,
    directoryName: String,
    source: InstanceSource,
    externalPath: URL?,
    iconPath: URL?
  ) {
    self.id = UUID().uuidString
    self.name = name
    self.versionId = versionId
    self.directoryName = directoryName
    self.createdAt = Date()
    self.lastModified = Date()
    self.source = source
    self.externalPath = externalPath
    self.iconPath = iconPath
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

    // Handle new fields with backward compatibility
    source = try container.decodeIfPresent(InstanceSource.self, forKey: .source) ?? .native

    if let externalPathString = try container.decodeIfPresent(String.self, forKey: .externalPath) {
      externalPath = URL(fileURLWithPath: externalPathString)
    } else {
      externalPath = nil
    }

    if let iconPathString = try container.decodeIfPresent(String.self, forKey: .iconPath) {
      iconPath = URL(fileURLWithPath: iconPathString)
    } else {
      iconPath = nil
    }
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
    try container.encode(source, forKey: .source)
    try container.encodeIfPresent(externalPath?.path, forKey: .externalPath)
    try container.encodeIfPresent(iconPath?.path, forKey: .iconPath)
  }

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case versionId
    case directoryName
    case createdAt
    case lastModified
    case source
    case externalPath
    case iconPath
  }
}
