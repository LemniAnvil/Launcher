//
//  PathManager.swift
//  Launcher
//
//  Unified path management system for the launcher
//

import Foundation

/// Path types used in the launcher
enum PathType: String, CaseIterable {
  // Minecraft standard paths
  case minecraftRoot = "minecraft_root"
  case versions = "versions"
  case libraries = "libraries"
  case assets = "assets"
  case assetIndexes = "asset_indexes"
  case assetObjects = "asset_objects"
  case logConfigs = "log_configs"

  // Launcher specific paths
  case launcherRoot = "launcher_root"
  case instances = "instances"
  case logs = "logs"
  case cache = "cache"
  case temp = "temp"
  case skins = "skins"
  case capes = "capes"

  // Java paths
  case javaInstallations = "java_installations"

  // Instance subdirectories
  case instanceMinecraft = "instance_minecraft"
  case instanceMods = "instance_mods"
  case instanceConfig = "instance_config"
  case instanceResourcePacks = "instance_resourcepacks"
  case instanceShaderPacks = "instance_shaderpacks"
  case instanceSaves = "instance_saves"
  case instanceScreenshots = "instance_screenshots"
  case instanceCrashReports = "instance_crash_reports"

  var description: String {
    switch self {
    case .minecraftRoot: return "Minecraft root directory"
    case .versions: return "Game versions"
    case .libraries: return "Game libraries"
    case .assets: return "Game assets"
    case .assetIndexes: return "Asset indexes"
    case .assetObjects: return "Asset objects"
    case .logConfigs: return "Log configurations"
    case .launcherRoot: return "Launcher data directory"
    case .instances: return "Game instances"
    case .logs: return "Launcher logs"
    case .cache: return "Cache directory"
    case .temp: return "Temporary files"
    case .skins: return "User skins"
    case .capes: return "User capes"
    case .javaInstallations: return "Java installations"
    case .instanceMinecraft: return "Instance Minecraft directory"
    case .instanceMods: return "Instance mods"
    case .instanceConfig: return "Instance configuration"
    case .instanceResourcePacks: return "Instance resource packs"
    case .instanceShaderPacks: return "Instance shader packs"
    case .instanceSaves: return "Instance saves"
    case .instanceScreenshots: return "Instance screenshots"
    case .instanceCrashReports: return "Instance crash reports"
    }
  }
}

/// Path configuration for the launcher
struct PathConfiguration: Codable {
  var minecraftRoot: String?
  var launcherRoot: String?
  var instancesRoot: String?
  var javaRoot: String?

  static let defaultConfiguration = Self()

  /// Get configuration file URL
  static var configFileURL: URL {
    let fileManager = FileManager.default
    // swiftlint:disable:next force_try
    let appSupport = try! fileManager.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
    return appSupport
      .appendingPathComponent("Launcher")
      .appendingPathComponent("path_config.json")
  }

  /// Load configuration from disk
  static func load() -> Self {
    guard let data = try? Data(contentsOf: configFileURL),
          let config = try? JSONDecoder().decode(Self.self, from: data)
    else {
      return defaultConfiguration
    }
    return config
  }

  /// Save configuration to disk
  func save() throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try encoder.encode(self)

    // Ensure directory exists
    let directory = Self.configFileURL.deletingLastPathComponent()
    try FileManager.default.createDirectory(
      at: directory,
      withIntermediateDirectories: true
    )

    try data.write(to: Self.configFileURL)
  }
}

/// Unified path manager for the launcher
final class PathManager {

  // MARK: - Singleton

  static let shared = PathManager()

  // MARK: - Properties

  private let fileManager = FileManager.default
  private var configuration: PathConfiguration
  private let queue = DispatchQueue(label: "com.launcher.pathmanager", attributes: .concurrent)

  // MARK: - Initialization

  private init() {
    self.configuration = PathConfiguration.load()
  }

  // MARK: - Configuration Management

  /// Get current configuration
  var currentConfiguration: PathConfiguration {
    queue.sync { configuration }
  }

  /// Update configuration
  func updateConfiguration(_ config: PathConfiguration) throws {
    try queue.sync(flags: .barrier) {
      try config.save()
      self.configuration = config
    }
  }

  /// Reset to default configuration
  func resetConfiguration() throws {
    try updateConfiguration(.defaultConfiguration)
  }

  // MARK: - Path Resolution

  /// Get path for a specific type
  func getPath(for type: PathType, createIfNeeded: Bool = true) -> URL {
    let path = resolvePath(for: type)

    if createIfNeeded {
      try? ensureDirectoryExists(at: path)
    }

    return path
  }

  /// Get path for a specific instance
  func getInstancePath(instanceId: String, subPath: PathType? = nil) -> URL {
    let instancesDir = getPath(for: .instances)
    let instanceDir = instancesDir.appendingPathComponent(instanceId)

    guard let subPath = subPath else {
      return instanceDir
    }

    let subDir: String
    switch subPath {
    case .instanceMinecraft:
      subDir = "minecraft"
    case .instanceMods:
      subDir = "minecraft/mods"
    case .instanceConfig:
      subDir = "minecraft/config"
    case .instanceResourcePacks:
      subDir = "minecraft/resourcepacks"
    case .instanceShaderPacks:
      subDir = "minecraft/shaderpacks"
    case .instanceSaves:
      subDir = "minecraft/saves"
    case .instanceScreenshots:
      subDir = "minecraft/screenshots"
    case .instanceCrashReports:
      subDir = "minecraft/crash-reports"
    default:
      return instanceDir
    }

    return instanceDir.appendingPathComponent(subDir)
  }

  /// Get version-specific path
  func getVersionPath(_ versionId: String) -> URL {
    getPath(for: .versions).appendingPathComponent(versionId)
  }

  /// Get library path from library name
  func getLibraryPath(from libraryName: String) -> URL {
    let components = libraryName.split(separator: ":")
    guard components.count >= 3 else {
      return getPath(for: .libraries).appendingPathComponent(libraryName)
    }

    let group = components[0].replacingOccurrences(of: ".", with: "/")
    let artifact = components[1]
    let version = components[2]

    var path = "\(group)/\(artifact)/\(version)/\(artifact)-\(version)"

    // Add classifier if present
    if components.count > 3 {
      path += "-\(components[3])"
    }

    path += ".jar"

    return getPath(for: .libraries).appendingPathComponent(path)
  }

  /// Get asset object path from hash
  func getAssetObjectPath(hash: String) -> URL {
    let prefix = String(hash.prefix(2))
    return getPath(for: .assetObjects)
      .appendingPathComponent(prefix)
      .appendingPathComponent(hash)
  }

  // MARK: - Path Variable Replacement

  /// Replace path variables in a string
  /// Supports: ${game_directory}, ${assets_root}, ${version_name}, etc.
  func replacingPathVariables(
    in string: String,
    instanceId: String? = nil,
    versionId: String? = nil
  ) -> String {
    var result = string

    // Game directory
    if let instanceId = instanceId {
      let gameDir = getInstancePath(instanceId: instanceId, subPath: .instanceMinecraft)
      result = result.replacingOccurrences(of: "${game_directory}", with: gameDir.path)
    }

    // Assets root
    let assetsRoot = getPath(for: .assets)
    result = result.replacingOccurrences(of: "${assets_root}", with: assetsRoot.path)

    // Version name
    if let versionId = versionId {
      result = result.replacingOccurrences(of: "${version_name}", with: versionId)
    }

    // Launcher root
    let launcherRoot = getPath(for: .launcherRoot)
    result = result.replacingOccurrences(of: "${launcher_root}", with: launcherRoot.path)

    return result
  }

  // MARK: - File Operations

  /// Ensure directory exists
  func ensureDirectoryExists(at url: URL) throws {
    var isDirectory: ObjCBool = false

    if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) {
      if !isDirectory.boolValue {
        throw PathManagerError.notADirectory(url)
      }
    } else {
      try fileManager.createDirectory(
        at: url,
        withIntermediateDirectories: true
      )
    }
  }

  /// Check if path exists
  func exists(at url: URL) -> Bool {
    fileManager.fileExists(atPath: url.path)
  }

  /// Get directory size
  func getDirectorySize(at url: URL) throws -> Int64 {
    var totalSize: Int64 = 0

    guard let enumerator = fileManager.enumerator(
      at: url,
      includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey]
    ) else {
      throw PathManagerError.cannotEnumerate(url)
    }

    for case let fileURL as URL in enumerator {
      guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
            let isRegularFile = resourceValues.isRegularFile,
            isRegularFile,
            let fileSize = resourceValues.fileSize
      else {
        continue
      }

      totalSize += Int64(fileSize)
    }

    return totalSize
  }

  /// Clean temporary files
  func cleanTemporaryFiles() throws {
    let tempDir = getPath(for: .temp, createIfNeeded: false)

    if fileManager.fileExists(atPath: tempDir.path) {
      try fileManager.removeItem(at: tempDir)
    }
  }

  /// Clean cache files older than specified days
  func cleanOldCache(olderThanDays days: Int) throws {
    let cacheDir = getPath(for: .cache)
    let cutoffDate = Date().addingTimeInterval(-Double(days) * AppConstants.Cache.secondsPerDay)

    guard let enumerator = fileManager.enumerator(
      at: cacheDir,
      includingPropertiesForKeys: [.contentModificationDateKey]
    ) else {
      return
    }

    for case let fileURL as URL in enumerator {
      guard let resourceValues = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]),
            let modificationDate = resourceValues.contentModificationDate,
            modificationDate < cutoffDate
      else {
        continue
      }

      try? fileManager.removeItem(at: fileURL)
    }
  }

  // MARK: - Private Methods

  private func resolvePath(for type: PathType) -> URL {
    let homeDir = fileManager.homeDirectoryForCurrentUser
    // swiftlint:disable:next force_try
    let appSupport = try! fileManager.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )

    switch type {
    // Minecraft paths
    case .minecraftRoot:
      if let customPath = configuration.minecraftRoot {
        return URL(fileURLWithPath: customPath)
      }
      return homeDir.appendingPathComponent(".minecraft")

    case .versions:
      return resolvePath(for: .minecraftRoot).appendingPathComponent("versions")

    case .libraries:
      return resolvePath(for: .minecraftRoot).appendingPathComponent("libraries")

    case .assets:
      return resolvePath(for: .minecraftRoot).appendingPathComponent("assets")

    case .assetIndexes:
      return resolvePath(for: .assets).appendingPathComponent("indexes")

    case .assetObjects:
      return resolvePath(for: .assets).appendingPathComponent("objects")

    case .logConfigs:
      return resolvePath(for: .assets).appendingPathComponent("log_configs")

    // Launcher paths
    case .launcherRoot:
      if let customPath = configuration.launcherRoot {
        return URL(fileURLWithPath: customPath)
      }
      return appSupport.appendingPathComponent("Launcher")

    case .instances:
      if let customPath = configuration.instancesRoot {
        return URL(fileURLWithPath: customPath)
      }
      return resolvePath(for: .launcherRoot).appendingPathComponent("instances")

    case .logs:
      return resolvePath(for: .launcherRoot).appendingPathComponent("logs")

    case .cache:
      return resolvePath(for: .launcherRoot).appendingPathComponent("cache")

    case .temp:
      return fileManager.temporaryDirectory.appendingPathComponent("Launcher")

    case .skins:
      return resolvePath(for: .launcherRoot).appendingPathComponent("Skins")
    case .capes:
      return resolvePath(for: .skins).appendingPathComponent("Capes")

    // Java paths
    case .javaInstallations:
      if let customPath = configuration.javaRoot {
        return URL(fileURLWithPath: customPath)
      }
      return resolvePath(for: .launcherRoot).appendingPathComponent("java")

    // Instance paths (should not be called directly)
    case .instanceMinecraft, .instanceMods, .instanceConfig, .instanceResourcePacks,
         .instanceShaderPacks, .instanceSaves, .instanceScreenshots, .instanceCrashReports:
      // These should be accessed through getInstancePath
      return resolvePath(for: .instances)
    }
  }
}

// MARK: - Errors

enum PathManagerError: LocalizedError {
  case notADirectory(URL)
  case cannotEnumerate(URL)
  case invalidPath(String)
  case configurationError(String)

  var errorDescription: String? {
    switch self {
    case let .notADirectory(url):
      return "Path is not a directory: \(url.path)"
    case let .cannotEnumerate(url):
      return "Cannot enumerate directory: \(url.path)"
    case let .invalidPath(path):
      return "Invalid path: \(path)"
    case let .configurationError(message):
      return "Configuration error: \(message)"
    }
  }
}

// MARK: - Compatibility Layer

/// Backward compatibility extension
extension PathManager {

  /// Get Minecraft directory (compatibility with FileUtils)
  var minecraftDirectory: URL {
    getPath(for: .minecraftRoot)
  }

  /// Get launcher directory (compatibility with FileUtils)
  var launcherDirectory: URL {
    getPath(for: .launcherRoot)
  }

  /// Get versions directory (compatibility with FileUtils)
  var versionsDirectory: URL {
    getPath(for: .versions)
  }

  /// Get instances directory (compatibility with FileUtils)
  var instancesDirectory: URL {
    getPath(for: .instances)
  }

  /// Get libraries directory (compatibility with FileUtils)
  var librariesDirectory: URL {
    getPath(for: .libraries)
  }

  /// Get assets directory (compatibility with FileUtils)
  var assetsDirectory: URL {
    getPath(for: .assets)
  }

  /// Get temporary directory (compatibility with FileUtils)
  var temporaryDirectory: URL {
    getPath(for: .temp)
  }
}
