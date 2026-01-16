//
//  Version.swift
//  Launcher
//
//  Minecraft version related data models
//

import CraftKit
import Foundation

// MARK: - Minecraft Namespace

/// Minecraft version-related namespace
/// Using enum as namespace to avoid polluting global namespace
enum Minecraft {

  // MARK: - Version Details Types

  /// Version details (version.json)
  struct VersionDetails: Codable {
    let id: String
    let type: String
    let time: String
    let releaseTime: String
    let inheritsFrom: String?
    let mainClass: String
    let minecraftArguments: String?
    let arguments: Arguments?
    let libraries: [Library]
    let assetIndex: AssetIndex
    let assets: String
    let downloads: Downloads
    let javaVersion: JavaVersion?
    let logging: Logging?
    let complianceLevel: Int?

    /// Get merged launch arguments (handles inheritance)
    func getMergedArguments() -> Arguments {
      if let args = arguments {
        return args
      }
      // Convert old format
      if let oldArgs = minecraftArguments {
        let gameArgs = oldArgs.split(separator: " ").map { String($0) }
        return Arguments(game: gameArgs.map { .string($0) }, jvm: nil)
      }
      return Arguments(game: nil, jvm: nil)
    }
  }

  // MARK: - Arguments Types

  /// Launch arguments
  struct Arguments: Codable {
    let game: [ArgumentValue]?
    let jvm: [ArgumentValue]?
  }

  /// Argument value (can be string or rule object)
  enum ArgumentValue: Codable {
    case string(String)
    case rule(ArgumentRule)

    init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()
      if let string = try? container.decode(String.self) {
        self = .string(string)
      } else if let rule = try? container.decode(ArgumentRule.self) {
        self = .rule(rule)
      } else {
        throw DecodingError.dataCorruptedError(
          in: container,
          debugDescription: "Unable to decode argument value"
        )
      }
    }

    func encode(to encoder: Encoder) throws {
      var container = encoder.singleValueContainer()
      switch self {
      case .string(let string):
        try container.encode(string)
      case .rule(let rule):
        try container.encode(rule)
      }
    }
  }

  /// Argument with rules
  struct ArgumentRule: Codable {
    let rules: [Rule]?
    let value: ArgumentRuleValue
  }

  /// Argument rule value
  enum ArgumentRuleValue: Codable {
    case string(String)
    case array([String])

    init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()
      if let string = try? container.decode(String.self) {
        self = .string(string)
      } else if let array = try? container.decode([String].self) {
        self = .array(array)
      } else {
        throw DecodingError.dataCorruptedError(
          in: container,
          debugDescription: "Unable to decode argument rule value"
        )
      }
    }

    func encode(to encoder: Encoder) throws {
      var container = encoder.singleValueContainer()
      switch self {
      case .string(let string):
        try container.encode(string)
      case .array(let array):
        try container.encode(array)
      }
    }
  }

  // MARK: - Rule Types

  /// Rule
  struct Rule: Codable {
    let action: RuleAction
    let os: OSRule?
    let features: [String: Bool]?
  }

  /// Rule action
  enum RuleAction: String, Codable {
    case allow = "allow"
    case disallow = "disallow"
  }

  /// Operating system rule
  struct OSRule: Codable {
    let name: String?
    let version: String?
    let arch: String?
  }

  // MARK: - Asset Types

  /// Asset index
  struct AssetIndex: Codable {
    let id: String
    let sha1: String
    let size: Int
    let totalSize: Int
    let url: String
  }

  // MARK: - Download Types

  /// Version download information
  struct Downloads: Codable {
    let client: DownloadInfo?
    let server: DownloadInfo?
    let clientMappings: DownloadInfo?
    let serverMappings: DownloadInfo?

    enum CodingKeys: String, CodingKey {
      case client
      case server
      case clientMappings = "client_mappings"
      case serverMappings = "server_mappings"
    }
  }

  /// Download information
  struct DownloadInfo: Codable {
    let sha1: String
    let size: Int
    let url: String
  }

  // MARK: - Java Types

  /// Java version requirement
  struct JavaVersion: Codable {
    let component: String
    let majorVersion: Int
  }

  // MARK: - Logging Types

  /// Logging configuration
  struct Logging: Codable {
    let client: LoggingClient?

    /// Logging client configuration
    struct LoggingClient: Codable {
      let argument: String
      let file: LoggingFile
      let type: String
    }

    /// Logging file information
    struct LoggingFile: Codable {
      let id: String
      let sha1: String
      let size: Int
      let url: String
    }
  }
}

// MARK: - Type Aliases

/// Type aliases - now using CraftKit types for version manifest
typealias VersionDetails = Minecraft.VersionDetails
typealias Arguments = Minecraft.Arguments
typealias ArgumentValue = Minecraft.ArgumentValue
typealias ArgumentRule = Minecraft.ArgumentRule
typealias ArgumentRuleValue = Minecraft.ArgumentRuleValue
typealias Rule = Minecraft.Rule
typealias RuleAction = Minecraft.RuleAction
typealias OSRule = Minecraft.OSRule
typealias AssetIndex = Minecraft.AssetIndex
typealias VersionDownloads = Minecraft.Downloads
typealias DownloadInfo = Minecraft.DownloadInfo
typealias JavaVersion = Minecraft.JavaVersion
typealias Logging = Minecraft.Logging
typealias LoggingClient = Minecraft.Logging.LoggingClient
typealias LoggingFile = Minecraft.Logging.LoggingFile
