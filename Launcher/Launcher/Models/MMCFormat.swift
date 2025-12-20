//
//  MMCFormat.swift
//  Launcher
//
//  MMC (MultiMC) format data models for Prism Launcher compatibility
//

import Foundation

/// MMC instance configuration (instance.cfg)
struct InstanceConfig {
  // Basic info
  var name: String
  var iconKey: String = "default"
  var notes: String = ""
  var instanceType: String = "OneSix"

  // Time tracking
  var lastLaunchTime: Int64 = 0
  var totalTimePlayed: Int64 = 0

  // Java settings
  var javaPath: String = ""
  var jvmArgs: String = ""
  var minMemAlloc: Int = 512  // MB
  var maxMemAlloc: Int = 2048 // MB
  var permGen: Int = 128      // MB (for older Java versions)

  // Game window settings
  var launchMaximized: Bool = false
  var minecraftWinWidth: Int = 854
  var minecraftWinHeight: Int = 480

  // Pre/Post launch commands
  var preLaunchCommand: String = ""
  var postExitCommand: String = ""
  var wrapperCommand: String = ""

  // Game settings
  var overrideCommands: Bool = false
  var overrideConsole: Bool = false
  var overrideJavaArgs: Bool = false
  var overrideJavaLocation: Bool = false
  var overrideMemory: Bool = false
  var overrideWindow: Bool = false

  // Misc
  var logPrePostOutput: Bool = true
  var autoCloseConsole: Bool = true
  var showConsole: Bool = true
  var showConsoleOnError: Bool = true

  /// Generate instance.cfg content
  func toConfigString() -> String {
    var lines: [String] = []
    lines.append("[General]")
    lines.append("ConfigVersion=1.2")
    lines.append("InstanceType=\(instanceType)")
    lines.append("iconKey=\(iconKey)")
    lines.append("name=\(name)")

    if !notes.isEmpty {
      lines.append("notes=\(notes)")
    }
    if lastLaunchTime > 0 {
      lines.append("lastLaunchTime=\(lastLaunchTime)")
    }
    if totalTimePlayed > 0 {
      lines.append("totalTimePlayed=\(totalTimePlayed)")
    }

    // Java settings
    if overrideJavaLocation && !javaPath.isEmpty {
      lines.append("JavaPath=\(javaPath)")
    }
    if overrideJavaArgs && !jvmArgs.isEmpty {
      lines.append("JvmArgs=\(jvmArgs)")
    }
    if overrideMemory {
      lines.append("MinMemAlloc=\(minMemAlloc)")
      lines.append("MaxMemAlloc=\(maxMemAlloc)")
      lines.append("PermGen=\(permGen)")
    }

    // Window settings
    if overrideWindow {
      lines.append("LaunchMaximized=\(launchMaximized)")
      if !launchMaximized {
        lines.append("MinecraftWinWidth=\(minecraftWinWidth)")
        lines.append("MinecraftWinHeight=\(minecraftWinHeight)")
      }
    }

    // Commands
    if overrideCommands {
      if !preLaunchCommand.isEmpty {
        lines.append("PreLaunchCommand=\(preLaunchCommand)")
      }
      if !postExitCommand.isEmpty {
        lines.append("PostExitCommand=\(postExitCommand)")
      }
      if !wrapperCommand.isEmpty {
        lines.append("WrapperCommand=\(wrapperCommand)")
      }
    }

    // Console settings
    if overrideConsole {
      lines.append("LogPrePostOutput=\(logPrePostOutput)")
      lines.append("AutoCloseConsole=\(autoCloseConsole)")
      lines.append("ShowConsole=\(showConsole)")
      lines.append("ShowConsoleOnError=\(showConsoleOnError)")
    }

    // Override flags
    lines.append("OverrideCommands=\(overrideCommands)")
    lines.append("OverrideConsole=\(overrideConsole)")
    lines.append("OverrideJavaArgs=\(overrideJavaArgs)")
    lines.append("OverrideJavaLocation=\(overrideJavaLocation)")
    lines.append("OverrideMemory=\(overrideMemory)")
    lines.append("OverrideWindow=\(overrideWindow)")

    return lines.joined(separator: "\n") + "\n"
  }

  /// Parse instance.cfg content
  static func fromConfigString(_ content: String) -> Self? {
    var config = Self(name: "")

    let lines = content.components(separatedBy: .newlines)
    for line in lines {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      // Skip section headers and empty lines
      guard !trimmed.isEmpty, !trimmed.hasPrefix("["), trimmed.contains("=") else { continue }

      let parts = trimmed.split(separator: "=", maxSplits: 1).map(String.init)
      guard parts.count == 2 else { continue }

      let key = parts[0]
      let value = parts[1]

      switch key {
      // Basic info
      case "name":
        config.name = value
      case "iconKey":
        config.iconKey = value
      case "notes":
        config.notes = value
      case "lastLaunchTime":
        config.lastLaunchTime = Int64(value) ?? 0
      case "totalTimePlayed":
        config.totalTimePlayed = Int64(value) ?? 0
      case "InstanceType":
        config.instanceType = value

      // Java settings
      case "JavaPath":
        config.javaPath = value
      case "JvmArgs":
        config.jvmArgs = value
      case "MinMemAlloc":
        config.minMemAlloc = Int(value) ?? 512
      case "MaxMemAlloc":
        config.maxMemAlloc = Int(value) ?? 2048
      case "PermGen":
        config.permGen = Int(value) ?? 128

      // Window settings
      case "LaunchMaximized":
        config.launchMaximized = value.lowercased() == "true"
      case "MinecraftWinWidth":
        config.minecraftWinWidth = Int(value) ?? 854
      case "MinecraftWinHeight":
        config.minecraftWinHeight = Int(value) ?? 480

      // Commands
      case "PreLaunchCommand":
        config.preLaunchCommand = value
      case "PostExitCommand":
        config.postExitCommand = value
      case "WrapperCommand":
        config.wrapperCommand = value

      // Console settings
      case "LogPrePostOutput":
        config.logPrePostOutput = value.lowercased() == "true"
      case "AutoCloseConsole":
        config.autoCloseConsole = value.lowercased() == "true"
      case "ShowConsole":
        config.showConsole = value.lowercased() == "true"
      case "ShowConsoleOnError":
        config.showConsoleOnError = value.lowercased() == "true"

      // Override flags
      case "OverrideCommands":
        config.overrideCommands = value.lowercased() == "true"
      case "OverrideConsole":
        config.overrideConsole = value.lowercased() == "true"
      case "OverrideJavaArgs":
        config.overrideJavaArgs = value.lowercased() == "true"
      case "OverrideJavaLocation":
        config.overrideJavaLocation = value.lowercased() == "true"
      case "OverrideMemory":
        config.overrideMemory = value.lowercased() == "true"
      case "OverrideWindow":
        config.overrideWindow = value.lowercased() == "true"

      default:
        break
      }
    }

    guard !config.name.isEmpty else { return nil }
    return config
  }
}

/// MMC pack format (mmc-pack.json)
struct MMCPack: Codable {
  var formatVersion: Int = 1
  var components: [MMCComponent]

  struct MMCComponent: Codable {
    var cachedName: String
    var cachedRequires: [MMCRequirement]?
    var cachedVersion: String
    var cachedVolatile: Bool
    var dependencyOnly: Bool
    var important: Bool
    var uid: String
    var version: String

    enum CodingKeys: String, CodingKey {
      case cachedName
      case cachedRequires
      case cachedVersion
      case cachedVolatile
      case dependencyOnly
      case important
      case uid
      case version
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      cachedName = try container.decode(String.self, forKey: .cachedName)
      cachedRequires = try container.decodeIfPresent([MMCRequirement].self, forKey: .cachedRequires)
      cachedVersion = try container.decode(String.self, forKey: .cachedVersion)
      cachedVolatile = try container.decodeIfPresent(Bool.self, forKey: .cachedVolatile) ?? false
      dependencyOnly = try container.decodeIfPresent(Bool.self, forKey: .dependencyOnly) ?? false
      important = try container.decodeIfPresent(Bool.self, forKey: .important) ?? false
      uid = try container.decode(String.self, forKey: .uid)
      version = try container.decode(String.self, forKey: .version)
    }

    init(
      uid: String,
      version: String,
      cachedName: String,
      cachedVersion: String,
      cachedRequires: [MMCRequirement]? = nil,
      cachedVolatile: Bool = false,
      dependencyOnly: Bool = false,
      important: Bool = false
    ) {
      self.uid = uid
      self.version = version
      self.cachedName = cachedName
      self.cachedVersion = cachedVersion
      self.cachedRequires = cachedRequires
      self.cachedVolatile = cachedVolatile
      self.dependencyOnly = dependencyOnly
      self.important = important
    }
  }

  struct MMCRequirement: Codable {
    var equals: String?
    var suggests: String?
    var uid: String

    init(uid: String, equals: String? = nil, suggests: String? = nil) {
      self.uid = uid
      self.equals = equals
      self.suggests = suggests
    }
  }

  /// Create MMC pack for vanilla Minecraft
  static func createVanillaPack(minecraftVersion: String) -> Self {
    let components = [
      MMCComponent(
        uid: "net.minecraft",
        version: minecraftVersion,
        cachedName: "Minecraft",
        cachedVersion: minecraftVersion,
        cachedRequires: [
          MMCRequirement(uid: "org.lwjgl3", suggests: "3.3.3")
        ],
        important: true
      ),
    ]

    return Self(formatVersion: 1, components: components)
  }

  /// Create MMC pack with mod loader
  static func createModdedPack(
    minecraftVersion: String,
    modLoader: String,
    modLoaderVersion: String
  ) -> Self {
    var components = [
      MMCComponent(
        uid: "net.minecraft",
        version: minecraftVersion,
        cachedName: "Minecraft",
        cachedVersion: minecraftVersion,
        cachedRequires: [
          MMCRequirement(uid: "org.lwjgl3", suggests: "3.3.3")
        ],
        important: true
      ),
    ]

    // Add mod loader component
    switch modLoader.lowercased() {
    case "forge":
      components.append(
        MMCComponent(
          uid: "net.minecraftforge",
          version: modLoaderVersion,
          cachedName: "Forge",
          cachedVersion: modLoaderVersion,
          cachedRequires: [
            MMCRequirement(uid: "net.minecraft", equals: minecraftVersion)
          ]
        )
      )
    case "fabric":
      components.append(
        MMCComponent(
          uid: "net.fabricmc.fabric-loader",
          version: modLoaderVersion,
          cachedName: "Fabric Loader",
          cachedVersion: modLoaderVersion,
          cachedRequires: [
            MMCRequirement(uid: "net.minecraft", equals: minecraftVersion)
          ]
        )
      )
    case "quilt":
      components.append(
        MMCComponent(
          uid: "org.quiltmc.quilt-loader",
          version: modLoaderVersion,
          cachedName: "Quilt Loader",
          cachedVersion: modLoaderVersion,
          cachedRequires: [
            MMCRequirement(uid: "net.minecraft", equals: minecraftVersion)
          ]
        )
      )
    case "neoforge":
      components.append(
        MMCComponent(
          uid: "net.neoforged",
          version: modLoaderVersion,
          cachedName: "NeoForge",
          cachedVersion: modLoaderVersion,
          cachedRequires: [
            MMCRequirement(uid: "net.minecraft", equals: minecraftVersion)
          ]
        )
      )
    default:
      break
    }

    return Self(formatVersion: 1, components: components)
  }

  /// Encode to JSON string
  func toJSONString() throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(self)
    return String(data: data, encoding: .utf8) ?? ""
  }

  /// Decode from JSON string
  static func fromJSONString(_ json: String) throws -> Self {
    guard let data = json.data(using: .utf8) else {
      throw NSError(domain: "MMCPack", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON string"])
    }
    let decoder = JSONDecoder()
    return try decoder.decode(Self.self, from: data)
  }
}
