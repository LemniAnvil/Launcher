//
//  GameLauncher.swift
//  Launcher
//
//  Game launching manager - responsible for launching Minecraft with Java
//

import Foundation
import CryptoKit

/// Game launcher manager
/// Implements GameLaunching protocol, providing concrete implementation for game launching
class GameLauncher: GameLaunching {  // ✅ Conforms to protocol
  // swiftlint:disable:previous type_body_length
  nonisolated(unsafe) static let shared = GameLauncher()

  private let logger = Logger.shared
  private let versionManager = VersionManager.shared
  private let javaManager = JavaManager.shared

  private init() {}

  // MARK: - Offline UUID Generation

  /// Generate offline UUID from username
  /// Uses UUID v3 (MD5) algorithm with namespace for consistency
  static func generateOfflineUUID(username: String) -> String {
    // Offline UUID namespace (same as Minecraft official offline UUID)
    let namespace = "OfflinePlayer:"
    let input = namespace + username

    // Calculate MD5 hash
    let data = Data(input.utf8)
    let hash = Insecure.MD5.hash(data: data)

    // Convert to UUID format
    let bytes = [UInt8](hash)
    let uuidString = String(
      format: "%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
      bytes[0],
      bytes[1],
      bytes[2],
      bytes[3],
      bytes[4],
      bytes[5],
      bytes[6],
      bytes[7],
      bytes[8],
      bytes[9],
      bytes[10],
      bytes[11],
      bytes[12],
      bytes[13],
      bytes[14],
      bytes[15]
    )

    return uuidString
  }

  // MARK: - Launch Configuration

  /// Launch configuration
  struct LaunchConfig {
    let versionId: String
    let javaPath: String
    let username: String
    let uuid: String
    let accessToken: String
    let maxMemory: Int // In MB
    let minMemory: Int // In MB
    let windowWidth: Int
    let windowHeight: Int

    static func `default`(versionId: String, javaPath: String, username: String? = nil) -> Self {
      let playerName = username ?? "Player"
      let offlineUUID = GameLauncher.generateOfflineUUID(username: playerName)

      return Self(
        versionId: versionId,
        javaPath: javaPath,
        username: playerName,
        uuid: offlineUUID,
        accessToken: "0",
        maxMemory: 2048,
        minMemory: 512,
        windowWidth: 854,
        windowHeight: 480
      )
    }
  }

  // MARK: - Public Methods

  /// Launch game
  @MainActor
  func launchGame(config: LaunchConfig) async throws {
    logger.info("Starting game launch: \(config.versionId)", category: "GameLauncher")

    // Check if version is installed
    guard versionManager.isVersionInstalled(versionId: config.versionId) else {
      throw GameLauncherError.versionNotInstalled(config.versionId)
    }

    // Get version details
    let versionDetails = try await versionManager.getVersionDetails(versionId: config.versionId)

    // Build launch arguments
    let arguments = try buildLaunchArguments(config: config, versionDetails: versionDetails)

    // Extract natives
    try await extractNatives(versionDetails: versionDetails, versionId: config.versionId)

    // Launch process
    try launchProcess(javaPath: config.javaPath, arguments: arguments, versionId: config.versionId)

    logger.info("Game launched successfully", category: "GameLauncher")
  }

  // MARK: - Private Methods

  /// Build launch arguments
  private func buildLaunchArguments(
    config: LaunchConfig,
    versionDetails: VersionDetails
  ) throws -> [String] {
    var arguments: [String] = []

    // JVM arguments
    let jvmArgs = buildJVMArguments(config: config, versionDetails: versionDetails)
    arguments.append(contentsOf: jvmArgs)

    // Main class
    arguments.append(versionDetails.mainClass)

    // Game arguments
    let gameArgs = try buildGameArguments(config: config, versionDetails: versionDetails)
    arguments.append(contentsOf: gameArgs)

    return arguments
  }

  /// Build JVM arguments
  private func buildJVMArguments(
    config: LaunchConfig,
    versionDetails: VersionDetails
  ) -> [String] {
    var args: [String] = []
    let nativesDir = getNativesDirectory(versionId: config.versionId)

    // Memory settings
    args.append("-Xms\(config.minMemory)M")
    args.append("-Xmx\(config.maxMemory)M")

    // macOS specific arguments
    args.append("-XstartOnFirstThread")

    // Logging configuration
    if let logging = versionDetails.logging?.client {
      let loggingFile = FileUtils.getAssetsDirectory()
        .appendingPathComponent("log_configs")
        .appendingPathComponent(logging.file.id)
      args.append(logging.argument.replacingOccurrences(of: "${path}", with: loggingFile.path))
    }

    // Process version-specific JVM arguments and replace variables
    if let jvmArguments = versionDetails.arguments?.jvm {
      for argValue in jvmArguments {
        if let processedArgs = processArgumentValue(argValue) {
          for arg in processedArgs {
            var replaced = arg
            replaced = replaced.replacingOccurrences(of: "${natives_directory}", with: nativesDir.path)
            replaced = replaced.replacingOccurrences(of: "${launcher_name}", with: "Launcher")
            replaced = replaced.replacingOccurrences(of: "${launcher_version}", with: "1.0")
            replaced = replaced.replacingOccurrences(of: "${classpath}", with: "")

            // Skip -cp arguments (we handle classpath separately)
            if replaced == "-cp" {
              continue
            }

            // Skip if still contains unreplaced variables or is empty
            if !replaced.isEmpty && !replaced.contains("${") {
              args.append(replaced)
            }
          }
        }
      }
    }

    // Classpath
    let classpath = try? buildClasspath(versionDetails: versionDetails, versionId: config.versionId)
    if let classpath = classpath {
      args.append("-cp")
      args.append(classpath)
    }

    return args
  }

  /// Build game arguments
  private func buildGameArguments(
    config: LaunchConfig,
    versionDetails: VersionDetails
  ) throws -> [String] {
    var args: [String] = []

    // Get game arguments from version details
    let gameArguments = versionDetails.getMergedArguments().game ?? []

    for argValue in gameArguments {
      if let processedArgs = processArgumentValue(argValue) {
        args.append(contentsOf: processedArgs)
      }
    }

    // Replace variables in arguments and filter out invalid ones
    var replacedArgs: [String] = []
    var skipNext = false

    for (index, arg) in args.enumerated() {
      if skipNext {
        skipNext = false
        continue
      }

      let replaced = replaceVariables(in: arg, config: config, versionDetails: versionDetails)

      // Skip arguments that contain unreplaced variables
      if replaced.contains("${") {
        // If this is a flag with a value, skip the next argument too
        if !replaced.hasPrefix("--") {
          continue
        }
        // Check if next arg exists and is a value (not a flag)
        if index + 1 < args.count && !args[index + 1].hasPrefix("--") {
          skipNext = true
        }
        continue
      }

      // Skip arguments that are empty strings
      if replaced.isEmpty {
        continue
      }

      // Skip demo mode flag (we want full game, not demo)
      if replaced == "--demo" {
        continue
      }

      // Skip argument flags that have empty values (like --clientId with empty value)
      if replaced.hasPrefix("--") {
        // Check if this flag has a value in the next argument
        if index + 1 < args.count {
          let nextArg = args[index + 1]
          let nextReplaced = replaceVariables(in: nextArg, config: config, versionDetails: versionDetails)
          // If the value is empty or contains unreplaced variables, skip both
          if nextReplaced.isEmpty || nextReplaced.contains("${") {
            skipNext = true
            continue
          }
        }
      }

      // Additional check: skip standalone flags that typically require values but we don't have
      let flagsRequiringValues = ["--clientId", "--xuid"]
      if flagsRequiringValues.contains(replaced) {
        // Check if next value exists and is valid
        if index + 1 < args.count {
          let nextArg = args[index + 1]
          let nextReplaced = replaceVariables(in: nextArg, config: config, versionDetails: versionDetails)
          if nextReplaced.isEmpty {
            skipNext = true
            continue
          }
        } else {
          // No value follows, skip this flag
          continue
        }
      }

      replacedArgs.append(replaced)
    }

    return replacedArgs
  }

  /// Process argument value (handle rules)
  private func processArgumentValue(_ argValue: ArgumentValue) -> [String]? {
    switch argValue {
    case .string(let string):
      return [string]

    case .rule(let rule):
      // Check if rule applies
      if let rules = rule.rules {
        var allowed = false
        for ruleItem in rules {
          if let osRule = ruleItem.os {
            if matchesCurrentOS(osRule) {
              allowed = (ruleItem.action == .allow)
            }
          } else {
            allowed = (ruleItem.action == .allow)
          }
        }

        if !allowed {
          return nil
        }
      }

      // Return rule value
      switch rule.value {
      case .string(let string):
        return [string]
      case .array(let array):
        return array
      }
    }
  }

  /// Check if OS rule matches current system
  private func matchesCurrentOS(_ osRule: OSRule) -> Bool {
    #if os(macOS)
      let osName = "osx"
    #elseif os(Linux)
      let osName = "linux"
    #else
      let osName = "windows"
    #endif

    if let name = osRule.name, name != osName {
      return false
    }

    return true
  }

  /// Replace variables in argument string
  private func replaceVariables(
    in argument: String,
    config: LaunchConfig,
    versionDetails: VersionDetails
  ) -> String {
    let minecraftDir = FileUtils.getMinecraftDirectory()
    let assetsDir = FileUtils.getAssetsDirectory()
    let nativesDir = getNativesDirectory(versionId: config.versionId)

    var result = argument
    result = result.replacingOccurrences(of: "${auth_player_name}", with: config.username)
    result = result.replacingOccurrences(of: "${version_name}", with: config.versionId)
    result = result.replacingOccurrences(of: "${game_directory}", with: minecraftDir.path)
    result = result.replacingOccurrences(of: "${assets_root}", with: assetsDir.path)
    result = result.replacingOccurrences(of: "${assets_index_name}", with: versionDetails.assetIndex.id)
    result = result.replacingOccurrences(of: "${auth_uuid}", with: config.uuid)
    result = result.replacingOccurrences(of: "${auth_access_token}", with: config.accessToken)
    result = result.replacingOccurrences(of: "${user_type}", with: "legacy")
    result = result.replacingOccurrences(of: "${user_properties}", with: "{}")
    result = result.replacingOccurrences(of: "${version_type}", with: versionDetails.type)
    result = result.replacingOccurrences(of: "${resolution_width}", with: "\(config.windowWidth)")
    result = result.replacingOccurrences(of: "${resolution_height}", with: "\(config.windowHeight)")
    result = result.replacingOccurrences(of: "${game_assets}", with: assetsDir.path)
    result = result.replacingOccurrences(of: "${natives_directory}", with: nativesDir.path)
    result = result.replacingOccurrences(of: "${launcher_name}", with: "Launcher")
    result = result.replacingOccurrences(of: "${launcher_version}", with: "1.0")
    result = result.replacingOccurrences(of: "${classpath}", with: "")

    // Client ID for Microsoft authentication (optional, use placeholder)
    result = result.replacingOccurrences(of: "${clientid}", with: "")
    result = result.replacingOccurrences(of: "${auth_xuid}", with: "")

    return result
  }

  /// Build classpath
  private func buildClasspath(versionDetails: VersionDetails, versionId: String) throws -> String {
    var classpathItems: [String] = []

    // Add all applicable libraries
    let librariesDir = FileUtils.getLibrariesDirectory()

    for library in versionDetails.libraries where library.isApplicable() {
      if let artifact = library.downloads?.artifact {
        let libraryPath = librariesDir.appendingPathComponent(artifact.path)
        if FileManager.default.fileExists(atPath: libraryPath.path) {
          classpathItems.append(libraryPath.path)
        }
      }
    }

    // Add game jar
    let versionDir = FileUtils.getVersionsDirectory().appendingPathComponent(versionId)
    let gameJar = versionDir.appendingPathComponent("\(versionId).jar")
    if FileManager.default.fileExists(atPath: gameJar.path) {
      classpathItems.append(gameJar.path)
    }

    return classpathItems.joined(separator: ":")
  }

  /// Extract native libraries
  private func extractNatives(versionDetails: VersionDetails, versionId: String) async throws {
    let nativesDir = getNativesDirectory(versionId: versionId)
    let librariesDir = FileUtils.getLibrariesDirectory()

    // Clean and recreate natives directory
    if FileManager.default.fileExists(atPath: nativesDir.path) {
      try FileManager.default.removeItem(at: nativesDir)
    }
    try FileManager.default.createDirectory(at: nativesDir, withIntermediateDirectories: true)

    // Extract native libraries
    for library in versionDetails.libraries where library.isApplicable() {
      guard let nativeName = library.getNativeName(),
            let classifiers = library.downloads?.classifiers,
            let nativeArtifact = classifiers[nativeName] else {
        continue
      }

      let libraryPath = librariesDir.appendingPathComponent(nativeArtifact.path)

      if FileManager.default.fileExists(atPath: libraryPath.path) {
        try extractZip(at: libraryPath, to: nativesDir, exclude: library.extract?.exclude)
      }
    }

    logger.info("Native libraries extracted to: \(nativesDir.path)", category: "GameLauncher")
  }

  /// Extract zip file
  private func extractZip(at sourceURL: URL, to destinationURL: URL, exclude: [String]?) throws {
    let fileManager = FileManager.default

    // Use unzip command to extract
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
    process.arguments = ["-o", "-q", sourceURL.path, "-d", destinationURL.path]

    try process.run()
    process.waitUntilExit()

    // Remove excluded files
    if let exclude = exclude {
      let contents = try fileManager.contentsOfDirectory(
        at: destinationURL,
        includingPropertiesForKeys: nil,
        options: []
      )

      for fileURL in contents {
        let relativePath = fileURL.lastPathComponent
        for pattern in exclude where relativePath.contains(pattern.replacingOccurrences(of: "META-INF/", with: "")) {
          try? fileManager.removeItem(at: fileURL)
        }
      }
    }
  }

  /// Get natives directory
  private func getNativesDirectory(versionId: String) -> URL {
    let versionDir = FileUtils.getVersionsDirectory().appendingPathComponent(versionId)
    return versionDir.appendingPathComponent("\(versionId)-natives")
  }

  /// Launch process
  private func launchProcess(javaPath: String, arguments: [String], versionId: String) throws {
    let javaBinary = javaPath.hasSuffix("java") ? javaPath : "\(javaPath)/bin/java"

    guard FileManager.default.fileExists(atPath: javaBinary) else {
      throw GameLauncherError.javaNotFound(javaBinary)
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: javaBinary)
    process.arguments = arguments
    process.currentDirectoryURL = FileUtils.getMinecraftDirectory()

    // Setup pipes for output
    let outputPipe = Pipe()
    let errorPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = errorPipe

    // Log output
    outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
      let data = handle.availableData
      if let output = String(data: data, encoding: .utf8), !output.isEmpty {
        self?.logger.info("[Game] \(output.trimmingCharacters(in: .whitespacesAndNewlines))", category: "GameLauncher")
      }
    }

    errorPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
      let data = handle.availableData
      if let output = String(data: data, encoding: .utf8), !output.isEmpty {
        self?.logger.error("[Game] \(output.trimmingCharacters(in: .whitespacesAndNewlines))", category: "GameLauncher")
      }
    }

    logger.info("Launching game with Java: \(javaBinary)", category: "GameLauncher")
    logger.debug("Launch arguments: \(arguments.joined(separator: " "))", category: "GameLauncher")

    try process.run()

    logger.info("Game process started (PID: \(process.processIdentifier))", category: "GameLauncher")
  }

  /// Get best Java installation for version
  @MainActor
  func getBestJavaForVersion(_ versionDetails: VersionDetails) async -> JavaInstallation? {
    let installations = await javaManager.detectJavaInstallations()

    guard !installations.isEmpty else {
      return nil
    }

    // Get required Java version
    let requiredMajorVersion = versionDetails.javaVersion?.majorVersion ?? 8

    // Find matching Java version
    for installation in installations {
      let versionComponents = installation.version.split(separator: ".")
      if let firstComponent = versionComponents.first,
         let majorVersion = Int(firstComponent.replacingOccurrences(of: "\"", with: "")),
         majorVersion >= requiredMajorVersion {
        return installation
      }
    }

    // Return first valid installation
    return installations.first { $0.isValid }
  }
}

// MARK: - Errors

enum GameLauncherError: LocalizedError {
  case versionNotInstalled(String)
  case javaNotFound(String)
  case launchFailed(String)

  var errorDescription: String? {
    switch self {
    case .versionNotInstalled(let version):
      return "Version not installed: \(version)"
    case .javaNotFound(let path):
      return "Java not found at: \(path)"
    case .launchFailed(let reason):
      return "Failed to launch game: \(reason)"
    }
  }
}
