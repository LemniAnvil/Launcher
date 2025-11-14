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
  // swiftlint:disable discouraged_optional_boolean
  let virtual: Bool?
  let mapToResources: Bool?
  // swiftlint:enable discouraged_optional_boolean

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
    return APIService.MinecraftResources.getResourceURL(hash: hash)
  }

  /// Get asset storage path
  func getPath() -> String {
    return APIService.MinecraftResources.getResourcePath(hash: hash)
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
