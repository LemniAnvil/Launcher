//
//  VersionManifestParser.swift
//  Launcher
//
//  Version manifest parser for Mojang's official API
//  API: https://launchermeta.mojang.com/mc/game/version_manifest.json
//

import Foundation

/// Version manifest parser
class VersionManifestParser {

  private let logger = Logger.shared

  // MARK: - API Endpoints

  /// Official Mojang launcher meta API
  static let officialManifestURL = APIEndpoints.versionManifestOfficial

  /// Alternative API (v2)
  static let alternativeManifestURL = APIEndpoints.versionManifestV2

  // MARK: - Public Methods

  /// Parse version manifest from JSON data
  func parseManifest(from data: Data) throws -> VersionManifest {
    let decoder = JSONDecoder()

    do {
      let manifest = try decoder.decode(VersionManifest.self, from: data)
      logger.info(
        "Manifest parsed successfully: \(manifest.versions.count) versions",
        category: "Parser"
      )
      return manifest
    } catch {
      logger.error("Failed to parse manifest: \(error)", category: "Parser")
      throw ParserError.manifestParseFailed(error)
    }
  }

  /// Parse version details from JSON data
  func parseVersionDetails(from data: Data) throws -> VersionDetails {
    let decoder = JSONDecoder()

    do {
      let details = try decoder.decode(VersionDetails.self, from: data)
      logger.info("Version details parsed: \(details.id)", category: "Parser")
      return details
    } catch {
      logger.error(
        "Failed to parse version details: \(error)",
        category: "Parser"
      )
      throw ParserError.versionDetailsParseFailed(error)
    }
  }

  /// Parse asset index from JSON data
  func parseAssetIndex(from data: Data) throws -> AssetIndexData {
    let decoder = JSONDecoder()

    do {
      let assetIndex = try decoder.decode(AssetIndexData.self, from: data)
      logger.info(
        "Asset index parsed: \(assetIndex.objects.count) objects",
        category: "Parser"
      )
      return assetIndex
    } catch {
      logger.error("Failed to parse asset index: \(error)", category: "Parser")
      throw ParserError.assetIndexParseFailed(error)
    }
  }

  /// Validate version manifest structure
  func validateManifest(_ manifest: VersionManifest) -> Bool {
    guard !manifest.versions.isEmpty else {
      logger.warning("Manifest has no versions", category: "Parser")
      return false
    }

    guard !manifest.latest.release.isEmpty else {
      logger.warning("Manifest has no latest release", category: "Parser")
      return false
    }

    guard !manifest.latest.snapshot.isEmpty else {
      logger.warning("Manifest has no latest snapshot", category: "Parser")
      return false
    }

    logger.info("Manifest validation passed", category: "Parser")
    return true
  }

  /// Validate version details structure
  func validateVersionDetails(_ details: VersionDetails) -> Bool {
    guard !details.id.isEmpty else {
      logger.warning("Version details has no ID", category: "Parser")
      return false
    }

    guard !details.mainClass.isEmpty else {
      logger.warning("Version details has no main class", category: "Parser")
      return false
    }

    guard !details.libraries.isEmpty else {
      logger.warning("Version details has no libraries", category: "Parser")
      return false
    }

    logger.info(
      "Version details validation passed for \(details.id)",
      category: "Parser"
    )
    return true
  }

  /// Extract version by ID from manifest
  func extractVersion(
    id: String,
    from manifest: VersionManifest
  ) -> MinecraftVersion? {
    return manifest.versions.first { $0.id == id }
  }

  /// Extract versions by type from manifest
  func extractVersions(
    type: VersionType,
    from manifest: VersionManifest
  ) -> [MinecraftVersion] {
    return manifest.versions.filter { $0.type == type }
  }

  /// Get latest version of specific type
  func getLatestVersion(
    type: VersionType,
    from manifest: VersionManifest
  ) -> MinecraftVersion? {
    let filtered = extractVersions(type: type, from: manifest)
    return filtered.first  // Already sorted by release time in manifest
  }

  /// Format version info for display
  func formatVersionInfo(_ version: MinecraftVersion) -> String {
    let date = formatDate(version.releaseTime)
    return "\(version.id) (\(version.type.displayName)) - Released: \(date)"
  }

  /// Format date string
  private func formatDate(_ isoDate: String) -> String {
    let formatter = ISO8601DateFormatter()
    guard let date = formatter.date(from: isoDate) else {
      return isoDate
    }

    let displayFormatter = DateFormatter()
    displayFormatter.dateStyle = .medium
    displayFormatter.timeStyle = .none
    return displayFormatter.string(from: date)
  }

  /// Export manifest to JSON file
  func exportManifest(_ manifest: VersionManifest, to url: URL) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    do {
      let data = try encoder.encode(manifest)
      try data.write(to: url)
      logger.info("Manifest exported to: \(url.path)", category: "Parser")
    } catch {
      logger.error("Failed to export manifest: \(error)", category: "Parser")
      throw ParserError.exportFailed(error)
    }
  }

  /// Generate version statistics
  func generateStatistics(from manifest: VersionManifest) -> VersionStatistics {
    let releaseCount = extractVersions(type: .release, from: manifest).count
    let snapshotCount = extractVersions(type: .snapshot, from: manifest).count
    let betaCount = extractVersions(type: .oldBeta, from: manifest).count
    let alphaCount = extractVersions(type: .oldAlpha, from: manifest).count

    return VersionStatistics(
      totalVersions: manifest.versions.count,
      releaseCount: releaseCount,
      snapshotCount: snapshotCount,
      betaCount: betaCount,
      alphaCount: alphaCount,
      latestRelease: manifest.latest.release,
      latestSnapshot: manifest.latest.snapshot
    )
  }
}

// MARK: - Supporting Types

/// Version statistics
struct VersionStatistics {
  let totalVersions: Int
  let releaseCount: Int
  let snapshotCount: Int
  let betaCount: Int
  let alphaCount: Int
  let latestRelease: String
  let latestSnapshot: String

  var summary: String {
    return """
      Total Versions: \(totalVersions)
      Releases: \(releaseCount)
      Snapshots: \(snapshotCount)
      Beta: \(betaCount)
      Alpha: \(alphaCount)
      Latest Release: \(latestRelease)
      Latest Snapshot: \(latestSnapshot)
      """
  }
}

/// Parser errors
enum ParserError: LocalizedError {
  case manifestParseFailed(Error)
  case versionDetailsParseFailed(Error)
  case assetIndexParseFailed(Error)
  case exportFailed(Error)
  case invalidData
  case invalidFormat

  var errorDescription: String? {
    switch self {
    case .manifestParseFailed(let error):
      return "Failed to parse manifest: \(error.localizedDescription)"
    case .versionDetailsParseFailed(let error):
      return "Failed to parse version details: \(error.localizedDescription)"
    case .assetIndexParseFailed(let error):
      return "Failed to parse asset index: \(error.localizedDescription)"
    case .exportFailed(let error):
      return "Failed to export: \(error.localizedDescription)"
    case .invalidData:
      return "Invalid data format"
    case .invalidFormat:
      return "Invalid JSON format"
    }
  }
}
