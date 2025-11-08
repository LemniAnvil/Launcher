//
//  InstanceManager.swift
//  Launcher
//
//  Instance Manager - responsible for managing Minecraft instances
//

import Combine
import Foundation

/// Instance Manager
@MainActor
class InstanceManager: ObservableObject {
  static let shared = InstanceManager()

  // MARK: - Published Properties

  @Published var instances: [Instance] = []

  // MARK: - Private Properties

  private let logger = Logger.shared
  private let instancesDirectory: URL

  // MARK: - Initialization

  private init() {
    self.instancesDirectory = FileUtils.getInstancesDirectory()

    logger.info("InstanceManager initializing...", category: "InstanceManager")
    logger.info("Instances directory: \(instancesDirectory.path)", category: "InstanceManager")

    // Load existing instances
    loadInstances()

    logger.info("InstanceManager initialized with \(instances.count) instances", category: "InstanceManager")
  }

  // MARK: - Public Methods

  /// Create a new instance
  func createInstance(name: String, versionId: String) throws -> Instance {
    logger.info("Creating instance: \(name) with version: \(versionId)", category: "InstanceManager")

    // Validate name
    guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw InstanceManagerError.invalidName("Instance name cannot be empty")
    }

    // Check if instance name already exists
    if instances.contains(where: { $0.name.lowercased() == name.lowercased() }) {
      throw InstanceManagerError.duplicateName(name)
    }

    // Validate version exists
    guard VersionManager.shared.isVersionInstalled(versionId: versionId) else {
      throw InstanceManagerError.versionNotInstalled(versionId)
    }

    // Create instance
    var instance = Instance(name: name, versionId: versionId)

    // Save instance to disk
    try saveInstance(instance)

    // Add to list
    instances.append(instance)

    logger.info("Instance created successfully: \(instance.id)", category: "InstanceManager")

    return instance
  }

  /// Delete an instance
  func deleteInstance(_ instance: Instance) throws {
    logger.info("Deleting instance: \(instance.id)", category: "InstanceManager")

    // Remove instance directory
    let instanceDir = instancesDirectory.appendingPathComponent(instance.id)
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
    return instancesDirectory.appendingPathComponent(instance.id)
  }

  /// Refresh instances list
  func refreshInstances() {
    loadInstances()
  }

  // MARK: - Private Methods

  /// Load instances from disk
  private func loadInstances() {
    instances = []

    guard let contents = try? FileManager.default.contentsOfDirectory(
      at: instancesDirectory,
      includingPropertiesForKeys: nil
    ) else {
      logger.warning("Failed to read instances directory", category: "InstanceManager")
      return
    }

    for url in contents {
      var isDirectory: ObjCBool = false
      guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
            isDirectory.boolValue else {
        continue
      }

      let instanceFile = url.appendingPathComponent("instance.json")
      guard FileManager.default.fileExists(atPath: instanceFile.path),
            let data = try? Data(contentsOf: instanceFile),
            let instance = try? JSONDecoder().decode(Instance.self, from: data) else {
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
    let instanceDir = instancesDirectory.appendingPathComponent(instance.id)
    try FileUtils.ensureDirectoryExists(at: instanceDir)

    let instanceFile = instanceDir.appendingPathComponent("instance.json")
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try encoder.encode(instance)
    try data.write(to: instanceFile)

    logger.debug("Instance saved: \(instanceFile.path)", category: "InstanceManager")
  }
}

// MARK: - Errors

enum InstanceManagerError: LocalizedError {
  case invalidName(String)
  case duplicateName(String)
  case versionNotInstalled(String)
  case instanceNotFound(String)
  case saveFailed(String)

  var errorDescription: String? {
    switch self {
    case .invalidName(let reason):
      return Localized.Instances.errorInvalidName(reason)
    case .duplicateName(let name):
      return Localized.Instances.errorDuplicateName(name)
    case .versionNotInstalled(let versionId):
      return Localized.Instances.errorVersionNotInstalled(versionId)
    case .instanceNotFound(let id):
      return Localized.Instances.errorInstanceNotFound(id)
    case .saveFailed(let reason):
      return Localized.Instances.errorSaveFailed(reason)
    }
  }
}

