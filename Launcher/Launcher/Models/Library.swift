//
//  Library.swift
//  Launcher
//
//  Dependency library related data models
//

import Foundation

/// Dependency library
struct Library: Codable {
  let name: String
  let downloads: LibraryDownloads?
  let rules: [Rule]?
  let natives: [String: String]?
  let extract: Extract?

  /// Get library path (based on Maven naming convention)
  func getPath() -> String {
    let components = name.split(separator: ":")
    guard components.count >= 3 else { return "" }

    let group = components[0].replacingOccurrences(of: ".", with: "/")
    let artifact = components[1]
    let version = components[2]
    let fileName: String

    if components.count > 3 {
      // With classifier, e.g. natives-osx
      let classifier = components[3]
      fileName = "\(artifact)-\(version)-\(classifier).jar"
    } else {
      fileName = "\(artifact)-\(version).jar"
    }

    return "\(group)/\(artifact)/\(version)/\(fileName)"
  }

  /// Check if library is applicable to current system
  func isApplicable() -> Bool {
    guard let rules = rules else { return true }

    var allowed = false
    for rule in rules {
      if let osRule = rule.os {
        if matchesOS(osRule) {
          allowed = (rule.action == .allow)
        }
      } else {
        allowed = (rule.action == .allow)
      }
    }
    return allowed
  }

  /// Check if OS matches
  private func matchesOS(_ osRule: OSRule) -> Bool {
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

    // Architecture check
    if let arch = osRule.arch {
      #if arch(arm64)
        let currentArch = "arm64"
      #else
        let currentArch = "x86_64"
      #endif

      if arch != currentArch {
        return false
      }
    }

    return true
  }

  /// Get native library name (if any)
  func getNativeName() -> String? {
    guard let natives = natives else { return nil }

    #if os(macOS)
      let osKey = "osx"
    #elseif os(Linux)
      let osKey = "linux"
    #else
      let osKey = "windows"
    #endif

    return natives[osKey]
  }
}

/// Library downloads
struct LibraryDownloads: Codable {
  let artifact: LibraryArtifact?
  let classifiers: [String: LibraryArtifact]?
}

/// Library artifact
struct LibraryArtifact: Codable {
  let path: String
  let sha1: String
  let size: Int
  let url: String
}

/// Extract configuration
struct Extract: Codable {
  let exclude: [String]?
}
