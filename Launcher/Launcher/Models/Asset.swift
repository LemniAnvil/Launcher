//
//  Asset.swift
//  Launcher
//
//  Game assets related data models
//

import Foundation

/// Asset index file (assets/indexes/xxx.json)
struct AssetIndexData: Codable {
  let objects: [String: AssetObject]
  let virtual: Bool?
  let mapToResources: Bool?

  enum CodingKeys: String, CodingKey {
    case objects
    case virtual
    case mapToResources = "map_to_resources"
  }
}

/// Asset object
struct AssetObject: Codable {
  let hash: String
  let size: Int

  /// Get asset download URL
  func getURL() -> String {
    let prefix = String(hash.prefix(2))
    return "https://resources.download.minecraft.net/\(prefix)/\(hash)"
  }

  /// Get asset storage path
  func getPath() -> String {
    let prefix = String(hash.prefix(2))
    return "\(prefix)/\(hash)"
  }
}

/// Asset download task
struct AssetDownloadTask {
  let name: String
  let hash: String
  let size: Int
  let url: String
  let destination: URL
}
