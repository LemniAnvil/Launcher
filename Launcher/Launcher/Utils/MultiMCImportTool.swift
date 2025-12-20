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
}

enum MultiMCImportError: LocalizedError {
  case missingMinecraftComponent(String)
  case invalidInstance(String)

  var errorDescription: String? {
    switch self {
    case let .missingMinecraftComponent(directory):
      return "Missing net.minecraft component in mmc-pack.json for instance: \(directory)"
    case let .invalidInstance(directory):
      return "Instance is invalid or missing required files: \(directory)"
    }
  }
}

final class MultiMCImportTool {

  private let fileManager: FileManager
  let instancesRoot: URL

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

    guard let minecraftComponent = pack.components.first(where: { $0.uid == "net.minecraft" }) else {
      throw MultiMCImportError.missingMinecraftComponent(url.lastPathComponent)
    }

    return MultiMCInstanceInfo(
      name: config.name,
      versionId: minecraftComponent.version,
      directoryName: url.lastPathComponent,
      path: url
    )
  }

  private func isDirectory(at url: URL) -> Bool {
    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
      return false
    }
    return isDirectory.boolValue
  }
}
