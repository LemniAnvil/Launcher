//
//  MMCFormat.swift
//  Launcher
//
//  MMC (MultiMC) format data models for Prism Launcher compatibility
//

import Foundation

/// MMC instance configuration (instance.cfg)
struct InstanceConfig {
  var name: String
  var iconKey: String = "default"
  var notes: String = ""
  var lastLaunchTime: Int64 = 0
  var totalTimePlayed: Int64 = 0
  var instanceType: String = "OneSix"

  /// Generate instance.cfg content
  func toConfigString() -> String {
    var lines: [String] = []
    lines.append("InstanceType=\(instanceType)")
    lines.append("name=\(name)")
    lines.append("iconKey=\(iconKey)")
    lines.append("notes=\(notes)")
    lines.append("lastLaunchTime=\(lastLaunchTime)")
    lines.append("totalTimePlayed=\(totalTimePlayed)")
    return lines.joined(separator: "\n") + "\n"
  }

  /// Parse instance.cfg content
  static func fromConfigString(_ content: String) -> Self? {
    var config = Self(name: "")

    let lines = content.components(separatedBy: .newlines)
    for line in lines {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      guard !trimmed.isEmpty, trimmed.contains("=") else { continue }

      let parts = trimmed.split(separator: "=", maxSplits: 1).map(String.init)
      guard parts.count == 2 else { continue }

      let key = parts[0]
      let value = parts[1]

      switch key {
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
          MMCRequirement(uid: "org.lwjgl3", suggests: "3.3.1")
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
          MMCRequirement(uid: "org.lwjgl3", suggests: "3.3.1")
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
