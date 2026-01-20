//
//  SkinMetadata.swift
//  Launcher
//
//  Metadata management for skin files using UUID + hash hybrid approach
//

import Foundation
import CryptoKit

// MARK: - Metadata Entry

/// Metadata for a single skin/cape file
struct SkinMetadataEntry: Codable, Equatable {
  let id: String  // UUID
  var fileName: String
  var fileHash: String  // SHA256 hash
  var displayName: String
  var tags: [String]
  var notes: String?
  var createdAt: Date
  var updatedAt: Date

  init(
    id: String = UUID().uuidString,
    fileName: String,
    fileHash: String,
    displayName: String,
    tags: [String] = [],
    notes: String? = nil,
    createdAt: Date = Date(),
    updatedAt: Date = Date()
  ) {
    self.id = id
    self.fileName = fileName
    self.fileHash = fileHash
    self.displayName = displayName
    self.tags = tags
    self.notes = notes
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}

// MARK: - Metadata Store

/// Root structure for metadata JSON file
struct SkinMetadataStore: Codable {
  var version: Int
  var skins: [String: SkinMetadataEntry]  // UUID -> Entry
  var capes: [String: SkinMetadataEntry]  // UUID -> Entry
  var hashIndex: [String: String]  // Hash -> UUID

  init(version: Int = 1) {
    self.version = version
    self.skins = [:]
    self.capes = [:]
    self.hashIndex = [:]
  }
}

// MARK: - Metadata Manager

enum SkinMetadataError: LocalizedError {
  case fileNotFound(URL)
  case invalidJSON
  case hashCalculationFailed
  case xattrFailed

  var errorDescription: String? {
    switch self {
    case .fileNotFound(let url):
      return "File not found: \(url.path)"
    case .invalidJSON:
      return "Invalid metadata JSON format"
    case .hashCalculationFailed:
      return "Failed to calculate file hash"
    case .xattrFailed:
      return "Failed to read/write extended attributes"
    }
  }
}

final class SkinMetadataManager {
  private let metadataFileURL: URL
  private let fileManager: FileManager
  private var store: SkinMetadataStore
  private var isStoreLoaded = false
  private var needsSave = false

  // Extended attribute key for storing UUID
  private let xattrKey = "com.launcher.skin.uuid"

  init(metadataFileURL: URL, fileManager: FileManager = .default) {
    self.metadataFileURL = metadataFileURL
    self.fileManager = fileManager
    self.store = SkinMetadataStore()
    // Don't load store in init - lazy load on first access
  }

  // MARK: - Store Management

  /// Lazy load metadata from JSON file
  private func ensureStoreLoaded() {
    guard !isStoreLoaded else { return }

    guard fileManager.fileExists(atPath: metadataFileURL.path) else {
      // Create new store if file doesn't exist
      store = SkinMetadataStore()
      isStoreLoaded = true
      return
    }

    do {
      let data = try Data(contentsOf: metadataFileURL)
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      store = try decoder.decode(SkinMetadataStore.self, from: data)
      isStoreLoaded = true
    } catch {
      print("⚠️ Failed to load metadata: \(error), creating new store")
      store = SkinMetadataStore()
      isStoreLoaded = true
    }
  }

  /// Save metadata to JSON file
  func saveStore() throws {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    let data = try encoder.encode(store)

    // Ensure directory exists
    let directory = metadataFileURL.deletingLastPathComponent()
    if !fileManager.fileExists(atPath: directory.path) {
      try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    try data.write(to: metadataFileURL, options: .atomic)
    needsSave = false
  }

  /// Batch save - mark that save is needed but don't save immediately
  private func markNeedsSave() {
    needsSave = true
  }

  /// Flush pending saves
  func flushIfNeeded() throws {
    if needsSave {
      try saveStore()
    }
  }

  // MARK: - Hash Calculation

  /// Calculate SHA256 hash of file
  func calculateFileHash(_ fileURL: URL) throws -> String {
    guard fileManager.fileExists(atPath: fileURL.path) else {
      throw SkinMetadataError.fileNotFound(fileURL)
    }

    let data = try Data(contentsOf: fileURL)
    let hash = SHA256.hash(data: data)
    return "sha256:" + hash.compactMap { String(format: "%02x", $0) }.joined()
  }

  // MARK: - Extended Attributes

  /// Read UUID from file's extended attributes
  func readUUIDFromFile(_ fileURL: URL) -> String? {
    let path = fileURL.path
    let bufferSize = 256
    var buffer = [UInt8](repeating: 0, count: bufferSize)

    let result = getxattr(path, xattrKey, &buffer, bufferSize, 0, 0)
    guard result > 0 else { return nil }

    let data = Data(buffer.prefix(result))
    return String(data: data, encoding: .utf8)
  }

  /// Write UUID to file's extended attributes
  func writeUUIDToFile(_ fileURL: URL, uuid: String) -> Bool {
    let path = fileURL.path
    guard let data = uuid.data(using: .utf8) else { return false }

    let result = data.withUnsafeBytes { buffer in
      setxattr(path, xattrKey, buffer.baseAddress, buffer.count, 0, 0)
    }

    return result == 0
  }

  // MARK: - Metadata Operations

  /// Get or create metadata for a file
  func getOrCreateMetadata(
    for fileURL: URL,
    kind: LauncherSkinAssetKind,
    defaultDisplayName: String? = nil
  ) throws -> SkinMetadataEntry {
    ensureStoreLoaded()

    // Step 1: Try to read UUID from extended attributes
    if let uuid = readUUIDFromFile(fileURL),
       let entry = getEntry(uuid: uuid, kind: kind) {
      return entry
    }

    // Step 2: Calculate file hash and try to find by hash
    let hash = try calculateFileHash(fileURL)
    if let uuid = store.hashIndex[hash],
       let entry = getEntry(uuid: uuid, kind: kind) {
      // Found by hash, write UUID to file for next time
      _ = writeUUIDToFile(fileURL, uuid: uuid)
      return entry
    }

    // Step 3: Create new metadata entry
    let fileName = fileURL.lastPathComponent
    let displayName = defaultDisplayName ?? fileURL.deletingPathExtension().lastPathComponent
    let uuid = UUID().uuidString

    let entry = SkinMetadataEntry(
      id: uuid,
      fileName: fileName,
      fileHash: hash,
      displayName: displayName
    )

    // Save to store
    setEntry(entry, kind: kind)
    store.hashIndex[hash] = uuid

    // Write UUID to file
    _ = writeUUIDToFile(fileURL, uuid: uuid)

    // Mark for batch save instead of saving immediately
    markNeedsSave()

    return entry
  }

  /// Update metadata entry
  func updateMetadata(
    uuid: String,
    kind: LauncherSkinAssetKind,
    displayName: String? = nil,
    tags: [String]? = nil,
    notes: String? = nil
  ) throws {
    ensureStoreLoaded()

    guard var entry = getEntry(uuid: uuid, kind: kind) else {
      return
    }

    if let displayName = displayName {
      entry.displayName = displayName
    }
    if let tags = tags {
      entry.tags = tags
    }
    if let notes = notes {
      entry.notes = notes
    }

    entry.updatedAt = Date()
    setEntry(entry, kind: kind)

    try saveStore()
  }

  /// Delete metadata entry
  func deleteMetadata(uuid: String, kind: LauncherSkinAssetKind) throws {
    ensureStoreLoaded()

    guard let entry = getEntry(uuid: uuid, kind: kind) else {
      return
    }

    // Remove from hash index
    store.hashIndex.removeValue(forKey: entry.fileHash)

    // Remove from store
    switch kind {
    case .skin:
      store.skins.removeValue(forKey: uuid)
    case .cape:
      store.capes.removeValue(forKey: uuid)
    }

    try saveStore()
  }

  /// Get all metadata entries for a kind
  func getAllMetadata(kind: LauncherSkinAssetKind) -> [SkinMetadataEntry] {
    ensureStoreLoaded()

    switch kind {
    case .skin:
      return Array(store.skins.values)
    case .cape:
      return Array(store.capes.values)
    }
  }

  // MARK: - Private Helpers

  private func getEntry(uuid: String, kind: LauncherSkinAssetKind) -> SkinMetadataEntry? {
    switch kind {
    case .skin:
      return store.skins[uuid]
    case .cape:
      return store.capes[uuid]
    }
  }

  private func setEntry(_ entry: SkinMetadataEntry, kind: LauncherSkinAssetKind) {
    switch kind {
    case .skin:
      store.skins[entry.id] = entry
    case .cape:
      store.capes[entry.id] = entry
    }
  }
}
