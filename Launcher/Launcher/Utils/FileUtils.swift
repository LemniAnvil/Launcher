//
//  FileUtils.swift
//  Launcher
//
//  File operation utilities
//

import CryptoKit
import Foundation

/// File utility enum
enum FileUtils {

  /// Get Minecraft directory
  static func getMinecraftDirectory() -> URL {
    let fileManager = FileManager.default
    let homeDir = fileManager.homeDirectoryForCurrentUser
    let minecraftDir = homeDir.appendingPathComponent(".minecraft")

    // Ensure directory exists
    try? fileManager.createDirectory(
      at: minecraftDir,
      withIntermediateDirectories: true
    )

    return minecraftDir
  }

  /// Get launcher data directory
  static func getLauncherDirectory() -> URL {
    let fileManager = FileManager.default
    // swiftlint:disable:next force_try
    let appSupport = try! fileManager.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
    let launcherDir = appSupport.appendingPathComponent("Launcher")

    try? fileManager.createDirectory(
      at: launcherDir,
      withIntermediateDirectories: true
    )

    return launcherDir
  }

  /// Get versions directory
  static func getVersionsDirectory() -> URL {
    let minecraftDir = getMinecraftDirectory()
    let versionsDir = minecraftDir.appendingPathComponent("versions")

    try? FileManager.default.createDirectory(
      at: versionsDir,
      withIntermediateDirectories: true
    )

    return versionsDir
  }

  /// Get instances directory
  static func getInstancesDirectory() -> URL {
    let launcherDir = getLauncherDirectory()
    let instancesDir = launcherDir.appendingPathComponent("instances")

    try? FileManager.default.createDirectory(
      at: instancesDir,
      withIntermediateDirectories: true
    )

    return instancesDir
  }

  /// Get libraries directory
  static func getLibrariesDirectory() -> URL {
    let minecraftDir = getMinecraftDirectory()
    let librariesDir = minecraftDir.appendingPathComponent("libraries")

    try? FileManager.default.createDirectory(
      at: librariesDir,
      withIntermediateDirectories: true
    )

    return librariesDir
  }

  /// Get assets directory
  static func getAssetsDirectory() -> URL {
    let minecraftDir = getMinecraftDirectory()
    let assetsDir = minecraftDir.appendingPathComponent("assets")

    try? FileManager.default.createDirectory(
      at: assetsDir,
      withIntermediateDirectories: true
    )

    return assetsDir
  }

  /// Calculate SHA1 hash of file
  static func calculateSHA1(of fileURL: URL) throws -> String {
    let data = try Data(contentsOf: fileURL)
    let digest = Insecure.SHA1.hash(data: data)
    return digest.map { String(format: "%02x", $0) }.joined()
  }

  /// Verify file SHA1
  static func verifySHA1(of fileURL: URL, expectedSHA1: String) -> Bool {
    guard let actualSHA1 = try? calculateSHA1(of: fileURL) else {
      return false
    }
    return actualSHA1.lowercased() == expectedSHA1.lowercased()
  }

  /// Ensure directory exists
  static func ensureDirectoryExists(at url: URL) throws {
    let fileManager = FileManager.default
    var isDirectory: ObjCBool = false

    if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) {
      if !isDirectory.boolValue {
        throw FileUtilsError.notADirectory(url)
      }
    } else {
      try fileManager.createDirectory(
        at: url,
        withIntermediateDirectories: true
      )
    }
  }

  /// Move file safely (remove destination if exists)
  static func moveFileSafely(from source: URL, to destination: URL) throws {
    let fileManager = FileManager.default

    // Ensure destination directory exists
    let destinationDir = destination.deletingLastPathComponent()
    try ensureDirectoryExists(at: destinationDir)

    // Remove destination file if exists
    if fileManager.fileExists(atPath: destination.path) {
      try fileManager.removeItem(at: destination)
    }

    // Move file
    try fileManager.moveItem(at: source, to: destination)
  }

  /// Get file size
  static func getFileSize(at url: URL) -> Int64? {
    guard
      let attributes = try? FileManager.default.attributesOfItem(
        atPath: url.path
      )
    else {
      return nil
    }
    return attributes[.size] as? Int64
  }

  /// Format bytes
  static func formatBytes(_ bytes: Int64) -> String {
    return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
  }

  /// Clean temporary files
  static func cleanTemporaryFiles() throws {
    let tempDir = FileManager.default.temporaryDirectory
    let launcherTempDir = tempDir.appendingPathComponent("Launcher")

    if FileManager.default.fileExists(atPath: launcherTempDir.path) {
      try FileManager.default.removeItem(at: launcherTempDir)
    }
  }

  /// Get temporary directory
  static func getTemporaryDirectory() -> URL {
    let tempDir = FileManager.default.temporaryDirectory
    let launcherTempDir = tempDir.appendingPathComponent("Launcher")

    try? FileManager.default.createDirectory(
      at: launcherTempDir,
      withIntermediateDirectories: true
    )

    return launcherTempDir
  }
}

/// File utility errors
enum FileUtilsError: LocalizedError {
  case notADirectory(URL)
  case fileNotFound(URL)
  case sha1Mismatch(expected: String, actual: String)

  var errorDescription: String? {
    switch self {
    case let .notADirectory(url):
      return "Path is not a directory: \(url.path)"
    case let .fileNotFound(url):
      return "File not found: \(url.path)"
    case let .sha1Mismatch(expected, actual):
      return "SHA1 mismatch: expected \(expected), got \(actual)"
    }
  }
}
