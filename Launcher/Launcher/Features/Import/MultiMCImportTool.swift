//
//  MultiMCImportTool.swift
//  Launcher
//
//  Utility to read MultiMC/PrismLauncher instances and surface basic metadata.
//

import Foundation

struct MultiMCInstanceInfo: Equatable {
  let name: String
  let versionId: String
  let directoryName: String
  let path: URL
  let iconPath: URL?
  let modLoader: String?
  let modLoaderVersion: String?

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.name == rhs.name
      && lhs.versionId == rhs.versionId
      && lhs.directoryName == rhs.directoryName
      && lhs.path == rhs.path
      && lhs.iconPath == rhs.iconPath
      && lhs.modLoader == rhs.modLoader
      && lhs.modLoaderVersion == rhs.modLoaderVersion
  }
}

enum MultiMCImportError: LocalizedError {
  case missingMinecraftComponent(String)
  case invalidInstance(String)

  var errorDescription: String? {
    switch self {
    case .missingMinecraftComponent(let directory):
      return "Missing net.minecraft component in mmc-pack.json for instance: \(directory)"
    case .invalidInstance(let directory):
      return "Instance is invalid or missing required files: \(directory)"
    }
  }
}

final class MultiMCImportTool {

  private let fileManager: FileManager
  let instancesRoot: URL

  /// Known mod loader UIDs
  private static let modLoaderUIDs: [String: String] = [
    "net.minecraftforge": "Forge",
    "net.fabricmc.fabric-loader": "Fabric",
    "org.quiltmc.quilt-loader": "Quilt",
    "net.neoforged.neoforge": "NeoForge",
  ]

  /// - Parameter instancesRoot: Root directory for MultiMC/PrismLauncher instances.
  ///   Defaults to the PrismLauncher instances path for the current user.
  init(
    instancesRoot: URL = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent("Library/Application Support/PrismLauncher/instances")
  ) {
    self.fileManager = .default
    self.instancesRoot = instancesRoot
  }

  /// Load all valid MultiMC/PrismLauncher instances under the root directory.
  func loadInstances() throws -> [MultiMCInstanceInfo] {
    guard fileManager.fileExists(atPath: instancesRoot.path) else {
      return []
    }

    let contents = try fileManager.contentsOfDirectory(
      at: instancesRoot,
      includingPropertiesForKeys: [.isDirectoryKey],
      options: [.skipsHiddenFiles]
    )

    var results: [MultiMCInstanceInfo] = []

    for candidate in contents {
      guard isDirectory(at: candidate) else { continue }
      if let instance = try loadInstance(at: candidate) {
        results.append(instance)
      }
    }

    return results
  }

  /// Attempt to load a single instance directory.
  private func loadInstance(at url: URL) throws -> MultiMCInstanceInfo? {
    let configURL = url.appendingPathComponent("instance.cfg")
    let packURL = url.appendingPathComponent("mmc-pack.json")

    guard
      fileManager.fileExists(atPath: configURL.path),
      fileManager.fileExists(atPath: packURL.path)
    else {
      return nil
    }

    let configContent = try String(contentsOf: configURL, encoding: .utf8)
    guard let config = InstanceConfig.fromConfigString(configContent) else {
      throw MultiMCImportError.invalidInstance(url.lastPathComponent)
    }

    let packData = try Data(contentsOf: packURL)
    let pack = try JSONDecoder().decode(MMCPack.self, from: packData)

    guard let minecraftComponent = pack.components.first(where: { $0.uid == "net.minecraft" })
    else {
      throw MultiMCImportError.missingMinecraftComponent(url.lastPathComponent)
    }

    // Find mod loader component
    let (modLoader, modLoaderVersion) = findModLoader(in: pack)

    // Find icon file
    let iconPath = findIconPath(at: url)

    return MultiMCInstanceInfo(
      name: config.name,
      versionId: minecraftComponent.version,
      directoryName: url.lastPathComponent,
      path: url,
      iconPath: iconPath,
      modLoader: modLoader,
      modLoaderVersion: modLoaderVersion
    )
  }

  /// Find mod loader from MMCPack components
  private func findModLoader(in pack: MMCPack) -> (String?, String?) {
    for component in pack.components {
      if let loaderName = Self.modLoaderUIDs[component.uid] {
        return (loaderName, component.version)
      }
    }
    return (nil, nil)
  }

  /// Find icon file in instance directory
  private func findIconPath(at url: URL) -> URL? {
    // Check for icon.png first (most common)
    let iconPng = url.appendingPathComponent("icon.png")
    if fileManager.fileExists(atPath: iconPng.path) {
      return iconPng
    }

    // Check for icon.jpg
    let iconJpg = url.appendingPathComponent("icon.jpg")
    if fileManager.fileExists(atPath: iconJpg.path) {
      return iconJpg
    }

    // Check for icon.jpeg
    let iconJpeg = url.appendingPathComponent("icon.jpeg")
    if fileManager.fileExists(atPath: iconJpeg.path) {
      return iconJpeg
    }

    return nil
  }

  private func isDirectory(at url: URL) -> Bool {
    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
      return false
    }
    return isDirectory.boolValue
  }
}
