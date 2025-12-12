//
//  FileUtils.swift
//  Launcher
//
//  File operation utilities
//

import CryptoKit
import Foundation

/// File utility enum
/// Note: Path-related functions now delegate to PathManager for better maintainability
enum FileUtils {

  /// Get Minecraft directory
  /// - Note: This function delegates to PathManager. Consider using PathManager.shared directly.
  static func getMinecraftDirectory() -> URL {
    PathManager.shared.getPath(for: .minecraftRoot)
  }

  /// Get launcher data directory
  /// - Note: This function delegates to PathManager. Consider using PathManager.shared directly.
  static func getLauncherDirectory() -> URL {
    PathManager.shared.getPath(for: .launcherRoot)
  }

  /// Get versions directory
  /// - Note: This function delegates to PathManager. Consider using PathManager.shared directly.
  static func getVersionsDirectory() -> URL {
    PathManager.shared.getPath(for: .versions)
  }

  /// Get instances directory
  /// - Note: This function delegates to PathManager. Consider using PathManager.shared directly.
  static func getInstancesDirectory() -> URL {
    PathManager.shared.getPath(for: .instances)
  }

  /// Get libraries directory
  /// - Note: This function delegates to PathManager. Consider using PathManager.shared directly.
  static func getLibrariesDirectory() -> URL {
    PathManager.shared.getPath(for: .libraries)
  }

  /// Get assets directory
  /// - Note: This function delegates to PathManager. Consider using PathManager.shared directly.
  static func getAssetsDirectory() -> URL {
    PathManager.shared.getPath(for: .assets)
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
  /// - Note: This function delegates to PathManager. Consider using PathManager.shared directly.
  static func getTemporaryDirectory() -> URL {
    PathManager.shared.getPath(for: .temp)
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
