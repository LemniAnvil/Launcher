//
//  VersionManager.swift
//  Launcher
//
//  Version Manager - responsible for fetching and managing Minecraft versions
//

import Combine
import Foundation

/// Version Manager
/// Implements VersionManaging protocol, providing concrete implementation for version management
@MainActor
class VersionManager: ObservableObject, VersionManaging {  // ✅ Conforms to protocol
  // swiftlint:disable:previous type_body_length
  static let shared = VersionManager()

  // MARK: - Published Properties

  @Published var versions: [MinecraftVersion] = []
  @Published var latestRelease: String?
  @Published var latestSnapshot: String?
  @Published var isLoading = false
  @Published var error: Error?

  // MARK: - Private Properties

  private let logger = Logger.shared
  private let parser = VersionManifestParser()
  private let downloadSettingsManager = DownloadSettingsManager.shared
  private var cachedManifest: VersionManifest?
  private let cacheURL: URL

  private var versionManifestURL: String {
    APIService.MinecraftVersion.getManifestURL(useV2: downloadSettingsManager.useV2Manifest)
  }

  // URLSession with proxy support
  private var urlSession: URLSession {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 30
    config.timeoutIntervalForResource = 300

    // Apply proxy configuration if enabled
    if let proxyDict = ProxyManager.shared.getProxyConfigurationForBoth() {
      config.connectionProxyDictionary = proxyDict
    }

    return URLSession(configuration: config)
  }

  // MARK: - Initialization

  private init() {
    let launcherDir = FileUtils.getLauncherDirectory()
    self.cacheURL = launcherDir.appendingPathComponent("version_cache.json")

    logger.info("VersionManager initializing...", category: "VersionManager")
    logger.info("Cache path: \(cacheURL.path)", category: "VersionManager")

    // Try to load cache
    loadCachedManifest()

    logger.info("VersionManager initialized with \(versions.count) versions", category: "VersionManager")
  }

  // MARK: - Public Methods

  /// Refresh version list
  func refreshVersionList() async throws {
    logger.info("Starting to refresh version list", category: "VersionManager")
    isLoading = true
    defer { isLoading = false }

    do {
      // Download version manifest
      let manifest = try await fetchVersionManifest()

      // Update state
      self.cachedManifest = manifest
      self.versions = manifest.versions
      self.latestRelease = manifest.latest.release
      self.latestSnapshot = manifest.latest.snapshot

      // Save cache
      try saveManifestToCache(manifest)

      logger.info(
        "Version list refreshed successfully, total \(manifest.versions.count) versions",
        category: "VersionManager"
      )
    } catch {
      logger.error(
        "Failed to refresh version list: \(error.localizedDescription)",
        category: "VersionManager"
      )
      self.error = error
      throw error
    }
  }

  /// Get version details for specified version
  func getVersionDetails(versionId: String) async throws -> VersionDetails {
    logger.info(
      "Getting version details: \(versionId)",
      category: "VersionManager"
    )

    // Find version
    guard let version = versions.first(where: { $0.id == versionId }) else {
      throw VersionManagerError.versionNotFound(versionId)
    }

    // Check local cache
    if let cached = loadCachedVersionDetails(versionId: versionId) {
      logger.debug(
        "Using cached version details: \(versionId)",
        category: "VersionManager"
      )
      return cached
    }

    // Download version details
    logger.info(
      "Downloading version details: \(version.url)",
      category: "VersionManager"
    )
    guard let url = URL(string: version.url) else {
      throw VersionManagerError.invalidURL(version.url)
    }

    let (data, response) = try await urlSession.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse,
      httpResponse.statusCode == 200
    else {
      throw VersionManagerError.downloadFailed("HTTP status code error")
    }

    // Parse JSON using parser
    let details = try parser.parseVersionDetails(from: data)

    // Validate details
    guard parser.validateVersionDetails(details) else {
      throw VersionManagerError.parseFailed("Version details validation failed")
    }

    // If inherits from another version, merge parent version
    let mergedDetails: VersionDetails
    if let inheritsFrom = details.inheritsFrom {
      logger.info(
        "Version \(versionId) inherits from \(inheritsFrom), merging",
        category: "VersionManager"
      )
      let parentDetails = try await getVersionDetails(versionId: inheritsFrom)
      mergedDetails = mergeVersionDetails(child: details, parent: parentDetails)
    } else {
      mergedDetails = details
    }

    // Save to local
    try saveVersionDetails(mergedDetails, versionId: versionId)

    logger.info(
      "Version details retrieved successfully: \(versionId)",
      category: "VersionManager"
    )
    return mergedDetails
  }

  /// Get filtered version list
  func getFilteredVersions(
    type: VersionType? = nil,
    searchText: String = ""
  ) -> [MinecraftVersion] {
    var filtered = versions

    // Filter by type
    if let type = type {
      filtered = filtered.filter { $0.type == type }
    }

    // Filter by search text
    if !searchText.isEmpty {
      filtered = filtered.filter {
        $0.id.localizedCaseInsensitiveContains(searchText)
      }
    }

    return filtered
  }

  /// Check if version is installed
  func isVersionInstalled(versionId: String) -> Bool {
    let versionDir = FileUtils.getVersionsDirectory().appendingPathComponent(
      versionId
    )
    let jarFile = versionDir.appendingPathComponent("\(versionId).jar")
    let jsonFile = versionDir.appendingPathComponent("\(versionId).json")

    return FileManager.default.fileExists(atPath: jarFile.path)
      && FileManager.default.fileExists(atPath: jsonFile.path)
  }

  /// Get list of installed versions
  func getInstalledVersions() -> [String] {
    let versionsDir = FileUtils.getVersionsDirectory()

    guard
      let contents = try? FileManager.default.contentsOfDirectory(
        at: versionsDir,
        includingPropertiesForKeys: nil
      )
    else {
      return []
    }

    return contents
      .filter { url in
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(
          atPath: url.path,
          isDirectory: &isDirectory
        )
        return isDirectory.boolValue
          && isVersionInstalled(versionId: url.lastPathComponent)
      }
      .map { $0.lastPathComponent }
  }

  // MARK: - Protocol Required Methods

  /// Get version by ID
  /// Implements VersionManaging protocol required method
  func getVersion(byId id: String) -> MinecraftVersion? {
    return versions.first { $0.id == id }
  }

  /// Download and install version
  /// Implements VersionManaging protocol required method
  /// - Parameter versionId: Version ID
  func downloadVersion(versionId: String) async throws {
    logger.info("Starting version download: \(versionId)", category: "VersionManager")

    // 1. Get version details
    let versionDetails = try await getVersionDetails(versionId: versionId)

    // 2. Download version files (JAR, libraries, etc.)
    try await DownloadManager.shared.downloadVersion(versionDetails)

    // 3. Download assets
    try await DownloadManager.shared.downloadAssets(assetIndexId: versionDetails.assetIndex.id)

    // 4. Save version JSON to disk
    let versionDir = FileUtils.getVersionsDirectory().appendingPathComponent(versionId)
    try FileUtils.ensureDirectoryExists(at: versionDir)

    let versionFile = versionDir.appendingPathComponent("\(versionId).json")
    let jsonData = try JSONEncoder().encode(versionDetails)
    try jsonData.write(to: versionFile)

    logger.info("Version download completed: \(versionId)", category: "VersionManager")
  }

  // MARK: - Private Methods

  /// Download version manifest
  private func fetchVersionManifest() async throws -> VersionManifest {
    logger.info("🌐 Attempting to download version manifest from network...", category: "VersionManager")

    // Try to download from network
    do {
      guard let url = URL(string: versionManifestURL) else {
        throw VersionManagerError.invalidURL(versionManifestURL)
      }

      logger.info("Requesting: \(versionManifestURL)", category: "VersionManager")
      let (data, response) = try await urlSession.data(from: url)

      guard let httpResponse = response as? HTTPURLResponse,
        httpResponse.statusCode == 200
      else {
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        logger.error("HTTP error, status code: \(statusCode)", category: "VersionManager")
        throw VersionManagerError.downloadFailed("HTTP status code: \(statusCode)")
      }

      logger.info("Downloaded \(data.count) bytes from network", category: "VersionManager")

      // Use parser to decode manifest
      let manifest = try parser.parseManifest(from: data)

      // Validate manifest
      guard parser.validateManifest(manifest) else {
        throw VersionManagerError.parseFailed("Manifest validation failed")
      }

      logger.info("✅ Version manifest downloaded from network successfully", category: "VersionManager")
      logger.info("Network manifest contains \(manifest.versions.count) versions", category: "VersionManager")
      return manifest
    } catch {
      // Network failed, try to load from local backup
      logger.warning(
        "❌ Failed to download version manifest from network: \(error.localizedDescription)",
        category: "VersionManager"
      )
      logger.info("📦 Attempting to load local versions.json as fallback...", category: "VersionManager")

      return try loadLocalBackupManifest()
    }
  }

  /// Load local backup version manifest
  private func loadLocalBackupManifest() throws -> VersionManifest {
    logger.info("Searching for versions.json in bundle resources...", category: "VersionManager")

    // Try to load from bundle resources
    guard let backupURL = Bundle.main.url(
      forResource: "versions",
      withExtension: "json"
    ) else {
      logger.error("❌ versions.json not found in bundle resources", category: "VersionManager")
      logger.error("Please ensure versions.json is added to Xcode project", category: "VersionManager")
      throw VersionManagerError.parseFailed("Local versions.json not found")
    }

    logger.info("✅ Found versions.json at: \(backupURL.path)", category: "VersionManager")

    do {
      let data = try Data(contentsOf: backupURL)
      logger.info("Read \(data.count) bytes from versions.json", category: "VersionManager")

      let manifest = try parser.parseManifest(from: data)
      logger.info("Parsed manifest with \(manifest.versions.count) versions", category: "VersionManager")

      // Validate manifest
      guard parser.validateManifest(manifest) else {
        logger.error("Manifest validation failed", category: "VersionManager")
        throw VersionManagerError.parseFailed("Local versions.json validation failed")
      }

      logger.info("✅ Loaded local versions.json successfully", category: "VersionManager")
      logger.info("Local manifest contains \(manifest.versions.count) versions", category: "VersionManager")
      logger.info("Latest release: \(manifest.latest.release)", category: "VersionManager")
      logger.info("Latest snapshot: \(manifest.latest.snapshot)", category: "VersionManager")

      return manifest
    } catch {
      logger.error(
        "❌ Failed to load local versions.json: \(error.localizedDescription)",
        category: "VersionManager"
      )
      throw VersionManagerError.parseFailed("Failed to load local backup: \(error.localizedDescription)")
    }
  }

  /// Merge version details (child version inherits parent version)
  private func mergeVersionDetails(
    child: VersionDetails,
    parent: VersionDetails
  ) -> VersionDetails {
    // Merge library list
    var mergedLibraries = parent.libraries
    mergedLibraries.append(contentsOf: child.libraries)

    // Merge arguments
    let mergedArguments: Arguments?
    if let childArgs = child.arguments {
      let parentArgs = parent.arguments ?? Arguments(game: nil, jvm: nil)
      let mergedGame = (parentArgs.game ?? []) + (childArgs.game ?? [])
      let mergedJVM = (parentArgs.jvm ?? []) + (childArgs.jvm ?? [])
      mergedArguments = Arguments(game: mergedGame, jvm: mergedJVM)
    } else {
      mergedArguments = child.arguments ?? parent.arguments
    }

    // Create merged version details
    return VersionDetails(
      id: child.id,
      type: child.type,
      time: child.time,
      releaseTime: child.releaseTime,
      inheritsFrom: nil,  // Already merged, no longer needs inheritance
      mainClass: child.mainClass,
      minecraftArguments: child.minecraftArguments ?? parent.minecraftArguments,
      arguments: mergedArguments,
      libraries: mergedLibraries,
      assetIndex: child.assetIndex,
      assets: child.assets,
      downloads: child.downloads,
      javaVersion: child.javaVersion ?? parent.javaVersion,
      logging: child.logging ?? parent.logging,
      complianceLevel: child.complianceLevel ?? parent.complianceLevel
    )
  }

  /// Save version manifest to cache
  private func saveManifestToCache(_ manifest: VersionManifest) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try encoder.encode(manifest)
    try data.write(to: cacheURL)
    logger.debug("Version manifest cached", category: "VersionManager")
  }

  /// Load cached version manifest
  private func loadCachedManifest() {
    logger.info("Checking for cached version manifest...", category: "VersionManager")
    logger.info("Cache file path: \(cacheURL.path)", category: "VersionManager")
    logger.info("Cache file exists: \(FileManager.default.fileExists(atPath: cacheURL.path))", category: "VersionManager")

    // Try to load from cache first
    if FileManager.default.fileExists(atPath: cacheURL.path),
      let data = try? Data(contentsOf: cacheURL),
      let manifest = try? JSONDecoder().decode(VersionManifest.self, from: data) {
      self.cachedManifest = manifest
      self.versions = manifest.versions
      self.latestRelease = manifest.latest.release
      self.latestSnapshot = manifest.latest.snapshot

      logger.info(
        "✅ Loaded cached version manifest, total \(manifest.versions.count) versions",
        category: "VersionManager"
      )
      logger.info("Latest release: \(manifest.latest.release)", category: "VersionManager")
      logger.info("Latest snapshot: \(manifest.latest.snapshot)", category: "VersionManager")
      return
    }

    // Cache not found or invalid, try to load local backup
    logger.warning("❌ No cached version manifest found or cache is invalid", category: "VersionManager")
    logger.info("📦 Attempting to load local versions.json...", category: "VersionManager")

    do {
      let manifest = try loadLocalBackupManifestSync()

      self.cachedManifest = manifest
      self.versions = manifest.versions
      self.latestRelease = manifest.latest.release
      self.latestSnapshot = manifest.latest.snapshot

      logger.info(
        "✅ Loaded local versions.json, total \(manifest.versions.count) versions",
        category: "VersionManager"
      )
      logger.info("Latest release: \(manifest.latest.release)", category: "VersionManager")
      logger.info("Latest snapshot: \(manifest.latest.snapshot)", category: "VersionManager")
    } catch {
      logger.error(
        "❌ Failed to load local versions.json: \(error.localizedDescription)",
        category: "VersionManager"
      )
      logger.error("Versions list will be empty until network refresh", category: "VersionManager")
      // No data available, versions will remain empty
    }
  }

  /// Load local backup manifest (synchronous version for init)
  private func loadLocalBackupManifestSync() throws -> VersionManifest {
    logger.info("Looking for versions.json in bundle resources...", category: "VersionManager")

    guard let backupURL = Bundle.main.url(
      forResource: "versions",
      withExtension: "json"
    ) else {
      logger.error("versions.json not found in bundle", category: "VersionManager")
      throw VersionManagerError.parseFailed("Local versions.json not found in bundle")
    }

    logger.info("Found versions.json at: \(backupURL.path)", category: "VersionManager")

    let data = try Data(contentsOf: backupURL)
    logger.info("Read \(data.count) bytes from versions.json", category: "VersionManager")

    let manifest = try parser.parseManifest(from: data)
    logger.info("Parsed manifest with \(manifest.versions.count) versions", category: "VersionManager")

    guard parser.validateManifest(manifest) else {
      logger.error("Manifest validation failed", category: "VersionManager")
      throw VersionManagerError.parseFailed("Local versions.json validation failed")
    }

    logger.info("✅ Manifest validation passed", category: "VersionManager")
    return manifest
  }

  /// Save version details to local
  private func saveVersionDetails(_ details: VersionDetails, versionId: String) throws {
    let versionDir = FileUtils.getVersionsDirectory().appendingPathComponent(
      versionId
    )
    try FileUtils.ensureDirectoryExists(at: versionDir)

    let jsonFile = versionDir.appendingPathComponent("\(versionId).json")
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try encoder.encode(details)
    try data.write(to: jsonFile)

    logger.debug(
      "Version details saved: \(jsonFile.path)",
      category: "VersionManager"
    )
  }

  /// Load cached version details
  private func loadCachedVersionDetails(versionId: String) -> VersionDetails? {
    let versionDir = FileUtils.getVersionsDirectory().appendingPathComponent(
      versionId
    )
    let jsonFile = versionDir.appendingPathComponent("\(versionId).json")

    guard FileManager.default.fileExists(atPath: jsonFile.path),
      let data = try? Data(contentsOf: jsonFile),
      let details = try? JSONDecoder().decode(VersionDetails.self, from: data)
    else {
      return nil
    }

    return details
  }
}

// MARK: - Errors

enum VersionManagerError: LocalizedError {
  case versionNotFound(String)
  case invalidURL(String)
  case downloadFailed(String)
  case parseFailed(String)

  var errorDescription: String? {
    switch self {
    case .versionNotFound(let version):
      return Localized.Errors.versionNotFound(version)
    case .invalidURL(let url):
      return Localized.Errors.invalidURL(url)
    case .downloadFailed(let reason):
      return Localized.Errors.downloadFailed(reason)
    case .parseFailed(let reason):
      return Localized.Errors.parseFailed(reason)
    }
  }
}
