//
//  SkinLibrary.swift
//  Launcher
//
//  Lightweight skin library reader/writer using PathManager for storage.
//

import Foundation

enum LauncherSkinAssetKind: String, Hashable {
  case skin
  case cape

  var displayName: String {
    switch self {
    case .skin: return "Skin"
    case .cape: return "Cape"
    }
  }
}

struct LauncherSkinAsset: Hashable {
  let name: String
  let fileURL: URL
  let fileSize: Int64
  let lastModified: Date
  let kind: LauncherSkinAssetKind
}

enum SkinLibraryError: LocalizedError {
  case unreadableDirectory(URL)
  case writeFailed(URL)

  var errorDescription: String? {
    switch self {
    case let .unreadableDirectory(url):
      return "Cannot read skins directory: \(url.path)"
    case let .writeFailed(url):
      return "Failed to write skin: \(url.path)"
    }
  }
}

final class SkinLibrary {
  private let pathManager: PathManager
  private let fileManager: FileManager
  private let directory: URL

  /// Public read-only access to the resolved skins directory.
  var libraryDirectory: URL { directory }

  init(
    pathManager: PathManager = .shared,
    fileManager: FileManager = .default,
    directory: URL? = nil
  ) {
    self.pathManager = pathManager
    self.fileManager = fileManager
    self.directory = directory ?? pathManager.getPath(for: .skins)
  }

  /// Ensure the skins directory exists.
  func ensureDirectory() throws {
    try pathManager.ensureDirectoryExists(at: directory)
  }

  /// List all png assets (skins + capes) with basic metadata.
  func listSkins() throws -> [LauncherSkinAsset] {
    try ensureDirectory()

    let contents: [URL]
    do {
      contents = try fileManager.contentsOfDirectory(
        at: directory,
        includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey, .isRegularFileKey],
        options: [.skipsHiddenFiles]
      )
    } catch {
      throw SkinLibraryError.unreadableDirectory(directory)
    }

    var result: [LauncherSkinAsset] = []
    let targets: [(URL, LauncherSkinAssetKind)] = [
      (directory, .skin),
      (pathManager.getPath(for: .capes), .cape),
    ]

    for (root, kind) in targets {
      guard fileManager.fileExists(atPath: root.path) else { continue }
      let entries: [URL]
      do {
        entries = try fileManager.contentsOfDirectory(
          at: root,
          includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey, .isRegularFileKey],
          options: [.skipsHiddenFiles]
        )
      } catch {
        throw SkinLibraryError.unreadableDirectory(root)
      }

      for url in entries where url.pathExtension.lowercased() == "png" {
        guard
          let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey, .isRegularFileKey]),
          values.isRegularFile == true,
          let size = values.fileSize
        else {
          continue
        }

        let name = url.deletingPathExtension().lastPathComponent
        let modified = values.contentModificationDate ?? Date(timeIntervalSince1970: 0)
        result.append(
          LauncherSkinAsset(
            name: name,
            fileURL: url,
            fileSize: Int64(size),
            lastModified: modified,
            kind: kind
          )
        )
      }
    }

    return result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
  }

  /// Save a skin PNG to the library.
  @discardableResult
  func saveSkin(named name: String, data: Data) throws -> URL {
    try ensureDirectory()
    let sanitized = name.isEmpty ? UUID().uuidString : name
    let destination = directory.appendingPathComponent("\(sanitized).png")

    do {
      try data.write(to: destination, options: .atomic)
      return destination
    } catch {
      throw SkinLibraryError.writeFailed(destination)
    }
  }

  /// Save a cape PNG to the library.
  @discardableResult
  func saveCape(named name: String, data: Data) throws -> URL {
    try pathManager.ensureDirectoryExists(at: pathManager.getPath(for: .capes))
    let sanitized = name.isEmpty ? UUID().uuidString : name
    let destination = pathManager.getPath(for: .capes).appendingPathComponent("\(sanitized).png")

    do {
      try data.write(to: destination, options: .atomic)
      return destination
    } catch {
      throw SkinLibraryError.writeFailed(destination)
    }
  }
}
