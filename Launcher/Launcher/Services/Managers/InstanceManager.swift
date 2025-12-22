//
//  InstanceManager.swift
//  Launcher
//
//  Instance Manager - responsible for managing Minecraft instances
//

import Combine
import Foundation

/// Instance Manager
/// Implements InstanceManaging protocol, providing concrete implementation for instance management
@MainActor
class InstanceManager: ObservableObject, InstanceManaging {  // ✅ Conforms to protocol
  static let shared = InstanceManager()

  // MARK: - Published Properties

  @Published var instances: [Instance] = []

  // MARK: - Private Properties

  private let logger = Logger.shared
  private let pathManager: PathManager
  private var instancesDirectory: URL {
    pathManager.getPath(for: .instances)
  }
  // ✅ Inject VersionManager dependency, no longer hardcoded
  private let versionManager: VersionManaging

  // MARK: - Initialization

  // ✅ Changed to public initialization method, supports dependency injection
  // Provides default parameters for backward compatibility
  init(
    versionManager: VersionManaging = VersionManager.shared,
    pathManager: PathManager = .shared
  ) {
    self.versionManager = versionManager
    self.pathManager = pathManager

    logger.info("InstanceManager initializing...", category: "InstanceManager")
    logger.info("Instances directory: \(instancesDirectory.path)", category: "InstanceManager")

    // Load existing instances
    loadInstances()

    logger.info("InstanceManager initialized with \(instances.count) instances", category: "InstanceManager")
  }

  // MARK: - Public Methods

  /// Create a new instance
  func createInstance(
    name: String,
    versionId: String,
    modLoader: String? = nil
  ) throws -> Instance {
    logger.info("Creating instance: \(name) with version: \(versionId)", category: "InstanceManager")

    // Validate name
    guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw InstanceManagerError.invalidName("Instance name cannot be empty")
    }

    // Note: Removed duplicate name check - users can create multiple instances with the same name
    // Each instance will have a unique directory based on version and UUID

    // Validate version exists in version manifest
    // Note: We don't require the version to be installed - it will be downloaded when launching
    // ✅ Use injected versionManager instead of hardcoded VersionManager.shared
    guard versionManager.versions.contains(where: { $0.id == versionId }) else {
      throw InstanceManagerError.versionNotFound(versionId)
    }

    // Create instance (automatically generates directoryName: "versionId-shortId")
    let instance = Instance(name: name, versionId: versionId)

    // Save instance to disk with MMC format
    try saveInstanceMMCFormat(instance, modLoader: modLoader)

    // Add to list
    instances.append(instance)

    logger.info(
      "Instance created successfully: \(instance.id) at directory: \(instance.directoryName)",
      category: "InstanceManager"
    )

    return instance
  }

  /// Delete an instance
  func deleteInstance(_ instance: Instance) throws {
    logger.info("Deleting instance: \(instance.id)", category: "InstanceManager")

    // Remove instance directory (use instance.directoryName)
    let instanceDir = pathManager.getInstancePath(instanceId: instance.directoryName)
    if FileManager.default.fileExists(atPath: instanceDir.path) {
      try FileManager.default.removeItem(at: instanceDir)
    }

    // Remove from list
    instances.removeAll { $0.id == instance.id }

    logger.info("Instance deleted successfully: \(instance.id)", category: "InstanceManager")
  }

  /// Get instance by ID
  func getInstance(byId id: String) -> Instance? {
    return instances.first { $0.id == id }
  }

  /// Get instance directory
  func getInstanceDirectory(for instance: Instance) -> URL {
    // Instance directory uses directoryName (format: "versionId-shortId")
    return pathManager.getInstancePath(instanceId: instance.directoryName)
  }

  /// Refresh instances list
  func refreshInstances() {
    loadInstances()
  }

  // MARK: - Private Methods

  /// Load instances from disk
  private func loadInstances() {
    instances = []

    guard
      let contents = try? FileManager.default.contentsOfDirectory(
        at: instancesDirectory,
        includingPropertiesForKeys: nil
      )
    else {
      logger.warning("Failed to read instances directory", category: "InstanceManager")
      return
    }

    for url in contents {
      var isDirectory: ObjCBool = false
      guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
        isDirectory.boolValue
      else {
        continue
      }

      // Try to load MMC format first (instance.cfg + mmc-pack.json)
      if let instance = loadInstanceMMCFormat(from: url) {
        instances.append(instance)
        continue
      }

      // Fallback to old format (instance.json)
      let instanceFile = url.appendingPathComponent("instance.json")
      guard FileManager.default.fileExists(atPath: instanceFile.path),
        let data = try? Data(contentsOf: instanceFile),
        let instance = try? JSONDecoder().decode(Instance.self, from: data)
      else {
        continue
      }

      instances.append(instance)
    }

    // Sort by last modified date (newest first)
    instances.sort { $0.lastModified > $1.lastModified }

    logger.info("Loaded \(instances.count) instances", category: "InstanceManager")
  }

  /// Save instance to disk
  private func saveInstance(_ instance: Instance) throws {
    let instanceDir = pathManager.getInstancePath(instanceId: instance.directoryName)
    try pathManager.ensureDirectoryExists(at: instanceDir)

    let instanceFile = instanceDir.appendingPathComponent("instance.json")
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try encoder.encode(instance)
    try data.write(to: instanceFile)

    logger.debug("Instance saved: \(instanceFile.path)", category: "InstanceManager")
  }

  /// Save instance with MMC format
  private func saveInstanceMMCFormat(_ instance: Instance, modLoader: String?) throws {
    // Use instance.directoryName (format: "versionId-shortId")
    let instanceId = instance.directoryName
    let instanceDir = pathManager.getInstancePath(instanceId: instanceId)

    // Create all standard directories via PathManager to keep names consistent
    let subdirectories: [PathType] = [
      .instanceMinecraft,
      .instanceMods,
      .instanceSaves,
      .instanceResourcePacks,
      .instanceShaderPacks,
      .instanceScreenshots,
      .instanceCrashReports,
      .instanceConfig,
    ]

    for subdir in subdirectories {
      let subdirPath = pathManager.getInstancePath(instanceId: instanceId, subPath: subdir)
      try pathManager.ensureDirectoryExists(at: subdirPath)
    }

    // Legacy/extra directories not covered by PathType
    let minecraftDir = pathManager.getInstancePath(instanceId: instanceId, subPath: .instanceMinecraft)
    let extraDirs = ["texturepacks", "coremods"]
    for extra in extraDirs {
      let extraPath = minecraftDir.appendingPathComponent(extra)
      try pathManager.ensureDirectoryExists(at: extraPath)
    }

    // Create instance.cfg
    let instanceConfig = InstanceConfig(name: instance.name)
    let configContent = instanceConfig.toConfigString()
    let configFile = instanceDir.appendingPathComponent("instance.cfg")
    try configContent.write(to: configFile, atomically: true, encoding: .utf8)

    // Create mmc-pack.json
    let mmcPack: MMCPack
    if let loader = modLoader, !loader.isEmpty && loader.lowercased() != "none" {
      // TODO: Get actual mod loader version
      mmcPack = MMCPack.createModdedPack(
        minecraftVersion: instance.versionId,
        modLoader: loader,
        modLoaderVersion: "latest"
      )
    } else {
      mmcPack = MMCPack.createVanillaPack(minecraftVersion: instance.versionId)
    }

    let packFile = instanceDir.appendingPathComponent("mmc-pack.json")
    let packJSON = try mmcPack.toJSONString()
    try packJSON.write(to: packFile, atomically: true, encoding: .utf8)

    // Also save instance.json for backward compatibility
    let instanceFile = instanceDir.appendingPathComponent("instance.json")
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try encoder.encode(instance)
    try data.write(to: instanceFile)

    logger.debug("Instance saved with MMC format: \(instanceDir.path)", category: "InstanceManager")
  }

  /// Load instance from MMC format
  private func loadInstanceMMCFormat(from directory: URL) -> Instance? {
    let configFile = directory.appendingPathComponent("instance.cfg")
    let packFile = directory.appendingPathComponent("mmc-pack.json")

    // Check if both files exist
    guard FileManager.default.fileExists(atPath: configFile.path),
      FileManager.default.fileExists(atPath: packFile.path)
    else {
      return nil
    }

    // Try to load from instance.json first (backward compatibility)
    let instanceFile = directory.appendingPathComponent("instance.json")
    if let data = try? Data(contentsOf: instanceFile), let instance = try? JSONDecoder().decode(Instance.self, from: data) {
      return instance
    }

    // Parse instance.cfg
    guard let configContent = try? String(contentsOf: configFile, encoding: .utf8),
      let config = InstanceConfig.fromConfigString(configContent)
    else {
      return nil
    }

    // Parse mmc-pack.json
    guard let packContent = try? String(contentsOf: packFile, encoding: .utf8),
      let pack = try? MMCPack.fromJSONString(packContent)
    else {
      return nil
    }

    // Find Minecraft version from components
    guard let minecraftComponent = pack.components.first(where: { $0.uid == "net.minecraft" })
    else {
      return nil
    }

    // Create instance from MMC data with directory name from file system
    let directoryName = directory.lastPathComponent
    let instance = Instance(
      name: config.name,
      versionId: minecraftComponent.version,
      directoryName: directoryName
    )

    return instance
  }
}

// MARK: - Errors

enum InstanceManagerError: LocalizedError {
  case invalidName(String)
  case duplicateName(String)
  case versionNotFound(String)
  case instanceNotFound(String)
  case saveFailed(String)

  var errorDescription: String? {
    switch self {
    case .invalidName(let reason):
      return Localized.Instances.errorInvalidName(reason)
    case .duplicateName(let name):
      return Localized.Instances.errorDuplicateName(name)
    case .versionNotFound(let versionId):
      return Localized.Instances.errorVersionNotFound(versionId)
    case .instanceNotFound(let id):
      return Localized.Instances.errorInstanceNotFound(id)
    case .saveFailed(let reason):
      return Localized.Instances.errorSaveFailed(reason)
    }
  }
}
